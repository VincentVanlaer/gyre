! Module   : gyre_jacobian_rad_jcd
! Purpose  : radial adiabatic Jacobian evaluation (JCD variables)
!
! Copyright 2013 Rich Townsend
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

module gyre_jacobian_rad_jcd

  ! Uses

  use core_kinds

  use gyre_jacobian
  use gyre_coeffs
  use gyre_oscpar

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Derived-type definitions

  type, extends (jacobian_t) :: jacobian_rad_jcd_t
     private
     class(coeffs_t), pointer :: cf => null()
     type(oscpar_t)           :: op
   contains
     private
     procedure, public :: eval => eval_
     procedure, public :: eval_logx => eval_logx_
     procedure, public :: trans_matrix => trans_matrix_
  end type jacobian_rad_jcd_t

  ! Interfaces

  interface jacobian_rad_jcd_t
     module procedure jacobian_rad_jcd_t_
  end interface jacobian_rad_jcd_t

  ! Access specifiers

  private

  public :: jacobian_rad_jcd_t

  ! Procedures

contains

  function jacobian_rad_jcd_t_ (cf, op) result (jc)

    class(coeffs_t), pointer, intent(in) :: cf
    type(oscpar_t), intent(in)           :: op
    type(jacobian_rad_jcd_t)             :: jc

    ! Construct the jacobian_rad_jcd_t

    jc%cf => cf
    jc%op = op

    jc%n_e = 2

    ! Finish

    return

  end function jacobian_rad_jcd_t_

!****

  subroutine eval_ (this, x, omega, A)

    class(jacobian_rad_jcd_t), intent(in) :: this
    real(WP), intent(in)                  :: x
    complex(WP), intent(in)               :: omega
    complex(WP), intent(out)              :: A(:,:)
    
    ! Evaluate the Jacobian matrix

    call this%eval_logx(x, omega, A)

    A = A/x

    ! Finish

    return

  end subroutine eval_

!****

  subroutine eval_logx_ (this, x, omega, A)

    class(jacobian_rad_jcd_t), intent(in) :: this
    real(WP), intent(in)                  :: x
    complex(WP), intent(in)               :: omega
    complex(WP), intent(out)              :: A(:,:)
    
    $CHECK_BOUNDS(SIZE(A, 1),this%n_e)
    $CHECK_BOUNDS(SIZE(A, 2),this%n_e)

    ! Evaluate the log(x)-space Jacobian matrix

    associate(V_g => this%cf%V(x)/this%cf%Gamma_1(x), U => this%cf%U(x), &
              As => this%cf%As(x), c_1 => this%cf%c_1(x), &
              omega_c => this%cf%omega_c(x, this%op%m, omega))

      A(1,1) = V_g - 1._WP
      A(1,2) = -V_g*c_1*omega_c**2
      
      A(2,1) = 1._WP - (As - U)/(c_1*omega_c**2)
      A(2,2) = As

    end associate

    ! Finish

    return

  end subroutine eval_logx_

!****

  function trans_matrix_ (this, x, omega, to_canon) result (M)

    class(jacobian_rad_jcd_t), intent(in) :: this
    real(WP), intent(in)                  :: x
    complex(WP), intent(in)               :: omega
    logical, intent(in)                   :: to_canon
    $if ($GFORTRAN_PR_58007)
    complex(WP), allocatable              :: M(:,:)
    $else
    complex(WP)                           :: M(this%n_e,this%n_e)
    $endif

    $if ($GFORTRAN_PR_58007)
    allocate(M(this%n_e,this%n_e))
    $endif

    ! Calculate the transformation matrix to convert variables between the
    ! canonical formulation and the JCD formulation

    if (to_canon) then

       associate(c_1 => this%cf%c_1(x), &
                 omega_c => this%cf%omega_c(x, this%op%m, omega))

         M(1,1) = 1._WP
         M(1,2) = 0._WP

         M(2,1) = 0._WP
         M(2,2) = c_1*omega_c**2

       end associate

    else

       associate(c_1 => this%cf%c_1(x), &
                 omega_c => this%cf%omega_c(x, this%op%m, omega))

         M(1,1) = 1._WP
         M(1,2) = 0._WP

         M(2,1) = 0._WP
         M(2,2) = 1._WP/(c_1*omega_c**2)

       end associate

    endif

    ! Finish

    return

  end function trans_matrix_

end module gyre_jacobian_rad_jcd
