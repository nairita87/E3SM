"""
API for actions related to model environment
"""

from XML.standard_module_setup import *
import CIME.utils
from CIME.utils import expect, run_cmd
from CIME.XML.machines import Machines
from CIME.XML.env_mach_specific import EnvMachSpecific

logger = logging.getLogger(__name__)

class EnvModule(object):

    # Public API

    def __init__(self, machine, compiler, cimeroot, caseroot, mpilib, debug=False):
        self._machine  = Machines(machine=machine)
        self._compiler = compiler
        self._cimeroot = cimeroot
        self._caseroot = caseroot
        self._mpilib   = mpilib
        self._debug    = debug
        self._cshscript = list()
        self._cshscript.append( self._mach_specific_header("csh"))
        self._shscript = list()
        self._shscript.append( self._mach_specific_header("sh"))
        self._module_system = self._machine.get_module_system_type()

    def load_env_for_case(self):
        mach_specific = EnvMachSpecific(caseroot=self._caseroot)

        module_nodes = mach_specific.get_nodes("modules")
        env_nodes    = mach_specific.get_nodes("environment_variables")

        if (module_nodes is not None):
            modules_to_load = self._compute_module_actions(module_nodes)
            self.load_modules(modules_to_load)
        if (env_nodes is not None):
            envs_to_set = self._compute_env_actions(env_nodes)
            self.load_envs(envs_to_set)
        with open(".env_mach_specific.csh",'w') as f:
            f.write("\n".join(self._cshscript))
        with open(".env_mach_specific.sh",'w') as f:
            f.write("\n".join(self._shscript))

    def load_modules(self, modules_to_load):

        if (self._module_system == "module"):
            self._load_module_modules(modules_to_load)
            self._cshscript += self._get_module_module_commands(modules_to_load,"csh")
            self._shscript += self._get_module_module_commands(modules_to_load,"sh")
        elif (self._module_system == "soft"):
            self._load_soft_modules(modules_to_load)
        elif (self._module_system == "dotkit"):
            self._load_dotkit_modules(modules_to_load)
        elif (self._module_system == "none"):
            self._load_none_modules(modules_to_load)
        else:
            expect(False, "Unhandled module system '%s'" % self._module_system)

    def load_envs(self, envs_to_set):
        for env_name, env_value in envs_to_set:
            # Let bash do the work on evaluating and resolving env_value
            os.environ[env_name] = run_cmd("echo %s" % env_value)
            self._cshscript.append("setenv %s %s"%(env_name,env_value))
            self._shscript.append("export %s=%s"%(env_name,env_value))

    # Private API

    def _compute_module_actions(self, module_nodes):
        return self._compute_actions(module_nodes, "command")

    def _compute_env_actions(self, env_nodes):
        return self._compute_actions(env_nodes, "env")

    def _compute_actions(self, nodes, child_tag):
        result = [] # list of tuples ("name", "argument")

        for node in nodes:
            if (self._match_attribs(node.attrib)):
                for child in node:
                    expect(child.tag == child_tag, "Expected %s element" % child_tag)
                    result.append( (child.get("name"), child.text) )

        return result

    def _match_attribs(self, attribs):
        if ("compiler" in attribs and
            not self._match(self._compiler, attribs["compiler"])):
            return False
        elif ("mpilib" in attribs and
            not self._match(self._mpilib, attribs["mpilib"])):
            return False
        elif ("debug" in attribs and
            not self._match("TRUE" if self._debug else "FALSE", attribs["debug"].upper())):
            return False

        return True

    def _match(self, my_value, xml_value):
        if (xml_value.startswith("!")):
            return my_value != xml_value[1:]
        else:
            return my_value == xml_value

    def _get_module_module_commands(self, modules_to_load, shell):
        mod_cmd = self._machine.get_module_system_cmd_path(shell)
        cmds = list()
        for action, argument in modules_to_load:
            if argument is None:
                argument = ""
            cmds.append("%s %s %s" % (mod_cmd, action, argument))
        return cmds

    def _load_module_modules(self, modules_to_load):
        for cmd in self._get_module_module_commands(modules_to_load, "python"):
            py_module_code = run_cmd(cmd)
            exec(py_module_code)

    def _load_soft_modules(self, modules_to_load):
        logging.info("Loading soft modules")
        sh_init_cmd = self._machine.get_module_system_init_path("sh")
        sh_mod_cmd = self._machine.get_module_system_cmd_path("sh")

        cmd = "source %s && source $SOFTENV_ALIASES && source $SOFTENV_LOAD" % (sh_init_cmd)

        for action,argument in modules_to_load:
            cmd += " && %s %s %s" % (sh_mod_cmd, action, argument)

        cmd += " && env"
        logging.debug("Command=%s" % cmd)
        output=run_cmd(cmd)

        newenv = {}
        for line in output.splitlines():
            m=re.match(r'^(\S+)=(\S+)$',line)
            if m:
                key = m.groups()[0]
                val = m.groups()[1]

                newenv[key] = val


        for key in newenv:
            if key in os.environ and key not in newenv:
                del(os.environ[key])
            else:
                os.environ[key] = newenv[key]



    def _load_dotkit_modules(self, modules_to_load):
        expect(False, "Not yet implemented")

    def _load_none_modules(self, modules_to_load):
        """
        No Action required
        """
        pass

    def _mach_specific_header(self, shell):
        '''
        write a shell module file for this case.
        '''
        header = '''
#!/usr/bin/env %s
#===============================================================================
# Automatically generated module settings for $self->{machine}
# DO NOT EDIT THIS FILE DIRECTLY!  Please edit env_mach_specific.xml
# in your CASEROOT. This file is overwritten every time modules are loaded!
#===============================================================================
'''%shell
        header += "source %s"%self._machine.get_module_system_init_path(shell)
        return header


