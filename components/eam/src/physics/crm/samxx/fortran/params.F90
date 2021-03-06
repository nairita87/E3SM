module params
  use iso_c_binding
  implicit none
  integer, parameter :: r8 = selected_real_kind(13)
  integer, parameter :: crm_rknd = selected_real_kind(13)
  integer, parameter :: crm_iknd = c_int
  integer, parameter :: crm_lknd = c_bool

  !   Constants:

  real(crm_rknd), parameter :: cp    = 1004.D0          ! Specific heat of air, J/kg/K
  real(crm_rknd), parameter :: ggr   = 9.81D0           ! Gravity acceleration, m/s2
  real(crm_rknd), parameter :: lcond = 2.5104D+06     ! Latent heat of condensation, J/kg
  real(crm_rknd), parameter :: lfus  = 0.3336D+06   ! Latent heat of fusion, J/kg
  real(crm_rknd), parameter :: lsub  = 2.8440D+06     ! Latent heat of sublimation, J/kg
  real(crm_rknd), parameter :: rv    = 461.D0           ! Gas constant for water vapor, J/kg/K
  real(crm_rknd), parameter :: rgas  = 287.D0           ! Gas constant for dry air, J/kg/K
  real(crm_rknd), parameter :: diffelq = 2.21D-05     ! Diffusivity of water vapor, m2/s
  real(crm_rknd), parameter :: therco = 2.40D-02      ! Thermal conductivity of air, J/m/s/K
  real(crm_rknd), parameter :: muelq = 1.717D-05      ! Dynamic viscosity of air

  real(crm_rknd), parameter :: fac_cond = lcond/cp
  real(crm_rknd), parameter :: fac_fus  = lfus/cp
  real(crm_rknd), parameter :: fac_sub  = lsub/cp

  real(crm_rknd), parameter ::  pi = 3.141592653589793D0



  !
  ! internally set parameters:

  real(crm_rknd)   epsv     ! = (1-eps)/eps, where eps= Rv/Ra, or =0. if dosmoke=.true.
  logical:: dosubsidence = .false.
  real(crm_rknd), allocatable :: fcorz(:)      ! Vertical Coriolis parameter

  !----------------------------------------------
  ! Parameters set by PARAMETERS namelist:
  ! Initialized to default values.
  !----------------------------------------------

  real(crm_rknd):: ug = 0.        ! Velocity of the Domain's drift in x direction
  real(crm_rknd):: vg = 0.        ! Velocity of the Domain's drift in y direction
  real(crm_rknd), allocatable :: fcor(:)  ! Coriolis parameter
  real(crm_rknd), allocatable :: longitude0(:)    ! latitude of the domain's center
  real(crm_rknd), allocatable :: latitude0 (:)    ! longitude of the domain's center

  real(crm_rknd), allocatable :: z0(:)            ! roughness length
  logical :: les =.false.    ! flag for Large-Eddy Simulation
  logical, allocatable :: ocean(:)           ! flag indicating that surface is water
  logical, allocatable :: land(:)            ! flag indicating that surface is land
  logical :: sfc_flx_fxd =.false. ! surface sensible flux is fixed
  logical :: sfc_tau_fxd =.false.! surface drag is fixed

  logical:: dodamping = .false.
  logical:: docloud = .false.
  logical:: doclubb = .false. ! Enabled the CLUBB parameterization (interactively)
  logical:: doclubb_sfc_fluxes = .false. ! Apply the surface fluxes within the CLUBB code rather than SAM
  logical:: doclubbnoninter = .false. ! Enable the CLUBB parameterization (non-interactively)
  logical:: docam_sfc_fluxes = .false.   ! Apply the surface fluxes within CAM
  logical:: doprecip = .false.
  logical:: dosgs = .false.
  logical:: docoriolis = .false.
  logical:: dosurface = .false.
  logical:: dowallx = .false.
  logical:: dowally = .false.
  logical:: docolumn = .false.
  logical:: dotracers = .false.
  logical:: dosmoke = .false.

  integer, parameter :: asyncid = 1

  integer:: nclubb = 1 ! SAM timesteps per CLUBB timestep

  real(crm_rknd), allocatable :: uhl(:)      ! current large-scale velocity in x near sfc
  real(crm_rknd), allocatable :: vhl(:)      ! current large-scale velocity in y near sfc
  real(crm_rknd), allocatable :: taux0(:)    ! surface stress in x, m2/s2
  real(crm_rknd), allocatable :: tauy0(:)    ! surface stress in y, m2/s2


contains

  
  subroutine allocate_params(ncrms)
    use openacc_utils
    implicit none
    integer, intent(in) :: ncrms
    allocate(fcor (ncrms))
    allocate(fcorz(ncrms))
    allocate(longitude0(ncrms))
    allocate(latitude0 (ncrms))
    allocate(z0        (ncrms))
    allocate(ocean     (ncrms))
    allocate(land      (ncrms))
    allocate(uhl       (ncrms))
    allocate(vhl       (ncrms))
    allocate(taux0     (ncrms))
    allocate(tauy0     (ncrms))

    call prefetch(fcor )
    call prefetch(fcorz)
    call prefetch(longitude0)
    call prefetch(latitude0 )
    call prefetch(z0)
    call prefetch(ocean)
    call prefetch(land)
    call prefetch(uhl)
    call prefetch(vhl)
    call prefetch(taux0)
    call prefetch(tauy0)

    fcor  = 0
    fcorz = 0
    longitude0 = 0
    latitude0  = 0
    z0 = 0.035D0
    ocean = .false.
    land = .false.
    uhl = 0
    vhl = 0
    taux0 = 0
    tauy0 = 0
  end subroutine allocate_params

  
  subroutine deallocate_params()
    implicit none
    deallocate(fcor )
    deallocate(fcorz)
    deallocate(longitude0)
    deallocate(latitude0 )
    deallocate(z0)
    deallocate(ocean)
    deallocate(land)
    deallocate(uhl)
    deallocate(vhl)
    deallocate(taux0)
    deallocate(tauy0)
  end subroutine deallocate_params


end module params
