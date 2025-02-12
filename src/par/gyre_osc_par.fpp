! Module   : gyre_osc_par
! Purpose  : oscillation parameters
!
! Copyright 2013-2020 Rich Townsend & The GYRE Team
!
! This file is part of GYRE. GYRE is free software: you can
! redistribute it and/or modify it under the terms of the GNU General
! Public License as published by the Free Software Foundation, version 3.
!
! GYRE is distributed in the hope that it will be useful, but WITHOUT
! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
! or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
! License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

$include 'core.inc'

module gyre_osc_par

  ! Uses

  use core_kinds

  use gyre_constants

  ! No implicit typing

  implicit none

  ! Derived-type definitions

  type :: osc_par_t
     real(WP)                :: x_ref = 1._WP
     real(WP)                :: x_atm = -1._WP
     real(WP)                :: alpha_grv = 1._WP
     real(WP)                :: alpha_thm = 1._WP
     real(WP)                :: alpha_hfl = 1._WP
     real(WP)                :: alpha_gam = 1._WP
     real(WP)                :: alpha_pi = 1._WP
     real(WP)                :: alpha_kar = 1._WP
     real(WP)                :: alpha_kat = 1._WP
     real(WP)                :: alpha_rht = 0._WP
     real(WP)                :: alpha_trb = 0._WP
     character(64)           :: variables_set = 'GYRE'
     character(64)           :: inner_bound = 'REGULAR'
     character(64)           :: outer_bound = 'VACUUM'
     character(64)           :: outer_bound_cutoff = ''
     character(64)           :: outer_bound_branch = 'E_NEG'
     character(64)           :: inertia_norm = 'BOTH'
     character(64)           :: time_factor = 'OSC'
     character(64)           :: conv_scheme = 'FROZEN_PESNELL_1'
     character(64)           :: zeta_scheme = 'UNNO'
     character(64)           :: deps_source = 'MODEL'
     character(FILENAME_LEN) :: deps_file = ''
     character(256)          :: deps_file_format = ''
     character(2048)         :: tag_list = ''
     logical                 :: adiabatic = .TRUE.
     logical                 :: nonadiabatic = .FALSE.
     logical                 :: quasiad_eigfuncs = .FALSE.
     logical                 :: reduce_order = .TRUE.
  end type osc_par_t

 ! Access specifiers

  private

  public :: osc_par_t
  public :: read_osc_par

  ! Procedures

contains

!****

  subroutine read_osc_par (unit, os_p)

    integer, intent(in)                       :: unit
    type(osc_par_t), allocatable, intent(out) :: os_p(:)

    integer                               :: n_os_p
    integer                               :: i
    real(WP)                              :: x_ref
    real(WP)                              :: x_atm
    real(WP)                              :: alpha_grv
    real(WP)                              :: alpha_thm
    real(WP)                              :: alpha_hfl
    real(WP)                              :: alpha_gam
    real(WP)                              :: alpha_pi
    real(WP)                              :: alpha_kar
    real(WP)                              :: alpha_kat
    real(WP)                              :: alpha_rht
    real(WP)                              :: alpha_trb
    character(LEN(os_p%variables_set))    :: variables_set
    character(LEN(os_p%inner_bound))      :: inner_bound
    character(LEN(os_p%outer_bound))      :: outer_bound
    character(LEN(os_p%outer_bound))      :: outer_bound_cutoff 
    character(LEN(os_p%outer_bound))      :: outer_bound_branch
    character(LEN(os_p%inertia_norm))     :: inertia_norm
    character(LEN(os_p%time_factor))      :: time_factor
    character(LEN(os_p%conv_scheme))      :: conv_scheme
    character(LEN(os_p%zeta_scheme))      :: zeta_scheme
    character(LEN(os_p%deps_source))      :: deps_source
    character(LEN(os_p%deps_file))        :: deps_file
    character(LEN(os_p%deps_file_format)) :: deps_file_format
    character(LEN(os_p%tag_list))         :: tag_list
    logical                               :: adiabatic
    logical                               :: nonadiabatic
    logical                               :: quasiad_eigfuncs
    logical                               :: reduce_order

    namelist /osc/ x_ref, x_atm, alpha_grv, alpha_thm, alpha_hfl, &
         alpha_gam, alpha_pi, alpha_kar, alpha_kat, alpha_rht, alpha_trb, &
         inner_bound, outer_bound, outer_bound_cutoff, outer_bound_branch, &
         variables_set, inertia_norm, time_factor, &
         conv_scheme, zeta_scheme, deps_source, deps_file, deps_file_format, &
         tag_list, adiabatic, nonadiabatic, quasiad_eigfuncs, &
         reduce_order

    ! Count the number of osc namelists

    rewind(unit)

    n_os_p = 0

    count_loop : do
       read(unit, NML=osc, END=100)
       n_os_p = n_os_p + 1
    end do count_loop

100 continue

    ! Read oscillation parameters

    rewind(unit)

    allocate(os_p(n_os_p))

    read_loop : do i = 1,n_os_p

       ! Set default values

       os_p(i) = osc_par_t()

       x_ref = os_p(i)%x_ref
       x_atm = os_p(i)%x_atm
       alpha_grv = os_p(i)%alpha_grv
       alpha_thm = os_p(i)%alpha_thm
       alpha_hfl = os_p(i)%alpha_hfl
       alpha_gam = os_p(i)%alpha_gam
       alpha_pi = os_p(i)%alpha_pi
       alpha_kar = os_p(i)%alpha_kar
       alpha_kat = os_p(i)%alpha_kat
       alpha_rht = os_p(i)%alpha_rht
       alpha_trb = os_p(i)%alpha_trb
       variables_set = os_p(i)%variables_set
       inner_bound = os_p(i)%inner_bound
       outer_bound = os_p(i)%outer_bound
       outer_bound_cutoff = os_p(i)%outer_bound_cutoff
       outer_bound_branch = os_p(i)%outer_bound_branch
       inertia_norm = os_p(i)%inertia_norm
       time_factor = os_p(i)%time_factor
       conv_scheme = os_p(i)%conv_scheme
       zeta_scheme = os_p(i)%zeta_scheme
       deps_source = os_p(i)%deps_source
       deps_file = os_p(i)%deps_file
       deps_file_format = os_p(i)%deps_file_format
       tag_list = os_p(i)%tag_list
       adiabatic = os_p(i)%adiabatic
       nonadiabatic = os_p(i)%nonadiabatic
       quasiad_eigfuncs = os_p(i)%quasiad_eigfuncs
       reduce_order = os_p(i)%reduce_order

       ! Read the namelist

       read(unit, NML=osc)

       ! Store read values

       os_p(i)%x_ref = x_ref
       os_p(i)%x_atm = x_atm
       os_p(i)%alpha_grv = alpha_grv
       os_p(i)%alpha_thm = alpha_thm
       os_p(i)%alpha_hfl = alpha_hfl
       os_p(i)%alpha_gam = alpha_gam
       os_p(i)%alpha_pi = alpha_pi
       os_p(i)%alpha_kar = alpha_kar
       os_p(i)%alpha_kat = alpha_kat
       os_p(i)%alpha_rht = alpha_rht
       os_p(i)%alpha_trb = alpha_trb
       os_p(i)%variables_set = variables_set
       os_p(i)%inner_bound = inner_bound
       os_p(i)%outer_bound = outer_bound
       os_p(i)%outer_bound_cutoff = outer_bound_cutoff
       os_p(i)%outer_bound_branch = outer_bound_branch
       os_p(i)%inertia_norm = inertia_norm
       os_p(i)%time_factor = time_factor
       os_p(i)%conv_scheme = conv_scheme
       os_p(i)%zeta_scheme = zeta_scheme
       os_p(i)%deps_source = deps_source
       os_p(i)%deps_file = deps_file
       os_p(i)%deps_file_format = deps_file_format
       os_p(i)%tag_list = tag_list
       os_p(i)%adiabatic = adiabatic
       os_p(i)%nonadiabatic = nonadiabatic
       os_p(i)%quasiad_eigfuncs = quasiad_eigfuncs
       os_p(i)%reduce_order = reduce_order

    end do read_loop

    ! Finish

    return

  end subroutine read_osc_par

end module gyre_osc_par
