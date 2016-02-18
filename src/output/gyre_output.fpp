! Program  : gyre_output
! Purpose  : output routines
!
! Copyright 2013-2016 Rich Townsend
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

module gyre_output

  ! Uses

  use core_kinds
  use core_string

  use gyre_constants
  use gyre_evol_model
  use gyre_hdf_writer
  use gyre_mode
  use gyre_model
  use gyre_out_par
  use gyre_poly_model
  use gyre_txt_writer
  use gyre_util
  use gyre_writer

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Access specifiers

  private

  public :: write_summary
  public :: write_mode

contains

  subroutine write_summary (md, ot_p)

    type(mode_t), intent(in)    :: md(:)
    type(out_par_t), intent(in) :: ot_p

    class(writer_t), allocatable                        :: wr
    character(LEN(ot_p%summary_item_list)), allocatable :: items(:)
    integer                                             :: n_md
    integer                                             :: i
    integer                                             :: j

    ! Write the summary file

    if (SIZE(md) == 0 .OR. ot_p%summary_file == '') return

    ! Open the file

    select case (ot_p%summary_file_format)
    case ('HDF')
       allocate(wr, SOURCE=hdf_writer_t(ot_p%summary_file, ot_p%label))
    case ('TXT')
       allocate(wr, SOURCE=txt_writer_t(ot_p%summary_file, ot_p%label))
    case default
       $ABORT(Invalid summary_file_format)
    end select

    ! Split the item list

    items = split_list(ot_p%summary_item_list, ',')

    ! Write the items

    n_md = SIZE(md)

    item_loop : do i = 1, SIZE(items)

       select case (items(i))

       case('l')
          call wr%write('l', md%l)
       case('l_i')
          call wr%write('l_i', [(md(j)%l_i, j=1,n_md)])
       case('m')
          call wr%write('m', md%m)
       case('n_p')
          call wr%write('n_p', md%n_p)
       case('n_g')
          call wr%write('n_g', md%n_g)
       case('n_pg')
          call wr%write('n_pg', md%n_pg)
       case('omega')
          call wr%write('omega', md%omega)
       case('freq')
          call wr%write('freq', [(md(j)%freq(ot_p%freq_units, ot_p%freq_frame), j=1,n_md)])
       case ('f_T')
          call wr%write('f_T', [(md(j)%f_T(), j=1,n_md)])
       case ('f_g')
          call wr%write('f_g', [(md(j)%f_g(), j=1,n_md)])
       case ('psi_T')
          call wr%write('psi_T', [(md(j)%psi_T(), j=1,n_md)])
       case ('psi_g')
          call wr%write('psi_g', [(md(j)%psi_g(), j=1,n_md)])
       case('E')
          call wr%write('E', [(md(j)%E(), j=1,n_md)])
       case('E_p')
          call wr%write('E_p', [(md(j)%E_p(), j=1,n_md)])
       case('E_g')
          call wr%write('E_g', [(md(j)%E_g(), j=1,n_md)])
       case('E_norm')
          call wr%write('E_norm', [(md(j)%E_norm(), j=1,n_md)])
       case('E_ratio')
          call wr%write('E_ratio', [(md(j)%E_p()/md(j)%E_g(), j=1,n_md)])
       case('W')
          call wr%write('W', [(md(j)%W(), j=1,n_md)])
       case('C')
          call wr%write('C', [(md(j)%C(), j=1,n_md)])
       case('omega_int')
          call wr%write('omega_int', [(md(j)%omega_int(), j=1,n_md)])
       case('eta')
          call wr%write('eta', [(md(j)%eta(), j=1,n_md)])
       case ('xi_r_ref')
          call wr%write('xi_r_ref', [(md(j)%xi_r(md(j)%s_ref, md(j)%x_ref), j=1,n_md)])
       case ('xi_h_ref')
          call wr%write('xi_h_ref', [(md(j)%xi_h(md(j)%s_ref, md(j)%x_ref), j=1,n_md)])
       case ('eul_phi_ref')
          call wr%write('eul_phi_ref', [(md(j)%eul_phi(md(j)%s_ref, md(j)%x_ref), j=1,n_md)])
       case ('deul_phi_ref')
          call wr%write('deul_phi_ref', [(md(j)%deul_phi(md(j)%s_ref, md(j)%x_ref), j=1,n_md)])
       case('freq_units')
          call wr%write('freq_units', ot_p%freq_units)
       case('freq_frame')
          call wr%write('freq_frame', ot_p%freq_frame)
       case default
          if (n_md >= 1) then
             select type (ml => md(1)%ml)
             type is (evol_model_t)
                call write_summary_evol_(items(i), ml, wr)
             class default
                write(ERROR_UNIT, *) 'item:', TRIM(items(i))
                $ABORT(Invalid item in summary_item_list)
             end select
          endif
       end select

    end do item_loop

    ! Close the file

    call wr%final()

    ! Finish

    return

  contains

    subroutine write_summary_evol_ (item, ml, wr)

      character(*), intent(in)       :: item
      type(evol_model_t), intent(in) :: ml
      class(writer_t), intent(inout) :: wr

      ! Write the item

      select case (items(i))
      case ('M_star')
         call wr%write('M_star', ml%M_star)
      case ('R_star')
         call wr%write('R_star', ml%R_star)
      case ('L_star')
         call wr%write('L_star', ml%L_star)
      case default
         write(ERROR_UNIT, *) 'item:', TRIM(items(i))
         $ABORT(Invalid item)
      end select

      ! Finish

      return

    end subroutine write_summary_evol_

  end subroutine write_summary

  !****

  subroutine write_mode (md, j, ot_p)

    type(mode_t), intent(in)    :: md
    integer, intent(in)         :: j
    type(out_par_t), intent(in) :: ot_p

    character(:), allocatable                        :: mode_file
    class(writer_t), allocatable                     :: wr
    character(LEN(ot_p%mode_item_list)), allocatable :: items(:)
    integer                                          :: i

    ! Write the mode file

    if (ot_p%mode_template == '') return

    if (filter_mode_(md, ot_p)) return

    ! Set up the filename

    mode_file = ot_p%mode_template

    mode_file = subst_(mode_file, '%J', j, '(I5.5)')
    mode_file = subst_(mode_file, '%L', md%l, '(I3.3)')
    mode_file = subst_(mode_file, '%N', md%n_pg, '(SP,I6.5)')

    mode_file = subst_(mode_file, '%j', j, '(I0)')
    mode_file = subst_(mode_file, '%l', md%l, '(I0)')
    mode_file = subst_(mode_file, '%n', md%n_pg, '(SP,I0)')

    ! Open the file

    select case (ot_p%mode_file_format)
    case ('HDF')
       allocate(wr, SOURCE=hdf_writer_t(mode_file, ot_p%label))
    case ('TXT')
       allocate(wr, SOURCE=txt_writer_t(mode_file, ot_p%label))
    case default
       $ABORT(Invalid mode_file_format)
    end select

    ! Split the item list

    items = split_list(ot_p%mode_item_list, ',')

    ! Write the items

    associate (s => md%s, x => md%x, &
               s_ref => md%s_ref, x_ref => md%x_ref)

      item_loop : do i = 1, SIZE(items)

         select case (items(i))
         case ('n')
            call wr%write('n', md%n_k)
         case ('l')
            call wr%write('l', md%l)
         case('l_i')
            call wr%write('l_i', md%l_i)
         case('m')
            call wr%write('m', md%m)
         case ('n_p')
            call wr%write('n_p', md%n_p)
         case ('n_g')
            call wr%write('n_g', md%n_g)
         case ('n_pg')
            call wr%write('n_pg', md%n_pg)
         case ('omega')
            call wr%write('omega', md%omega)
         case ('freq')
            call wr%write('freq', md%freq(ot_p%freq_units, ot_p%freq_frame))
         case ('f_T')
            call wr%write('f_T', md%f_T())
         case ('f_g')
            call wr%write('f_g', md%f_g())
         case ('psi_T')
            call wr%write('psi_T', md%psi_T())
         case ('psi_g')
            call wr%write('psi_g', md%psi_g())
         case ('C')
            call wr%write('C', md%C())
         case ('E')
            call wr%write('E', md%E())
         case ('E_p')
            call wr%write('E_p', md%E_p())
         case ('E_g')
            call wr%write('E_g', md%E_g())
         case ('E_norm')
            call wr%write('E_norm', md%E_norm())
         case('E_ratio')
            call wr%write('E_ratio',md%E_p()/md%E_g())
         case ('W')
            call wr%write('W', md%W())
         case('omega_int')
            call wr%write('omega_int', md%omega_int())
         case('eta')
            call wr%write('eta', md%eta())
         case ('x')
            call wr%write('x', x)
         case('V_2')
            call wr%write('V_2', md%ml%V_2(s, x))
         case('As')
            call wr%write('As', md%ml%As(s, x))
         case('U')
            call wr%write('U', md%ml%U(s, x))
         case('c_1')
            call wr%write('c_1', md%ml%c_1(s, x))
         case ('Gamma_1')
            call wr%write('Gamma_1', md%ml%Gamma_1(s, x))
         case ('nabla')
            call wr%write('nabla', md%ml%nabla(s, x))
         case ('nabla_ad')
            call wr%write('nabla_ad', md%ml%nabla_ad(s, x))
         case ('delta')
            call wr%write('delta', md%ml%delta(s, x))
         case ('Omega_rot')
            call wr%write('Omega_rot', md%ml%Omega_rot(s, x))
         case ('y_1')
            call wr%write('y_1', md%y(1, s, x))
         case ('y_2')
            call wr%write('y_2', md%y(2, s, x))
         case ('y_3')
            call wr%write('y_3', md%y(3, s, x))
         case ('y_4')
            call wr%write('y_4', md%y(4, s, x))
         case ('y_5')
            call wr%write('y_5', md%y(5, s, x))
         case ('y_6')
            call wr%write('y_6', md%y(6, s, x))
         case ('xi_r')
            call wr%write('xi_r', md%xi_r(s, x))
         case ('xi_h')
            call wr%write('xi_h', md%xi_h(s, x))
         case ('xi_r_ref')
            call wr%write('xi_r_ref', md%xi_r(s_ref, x_ref))
         case ('xi_h_ref')
            call wr%write('xi_h_ref', md%xi_h(s_ref, x_ref))
         case ('eul_phi')
            call wr%write('eul_phi', md%eul_phi(s, x))
         case ('deul_phi')
            call wr%write('deul_phi', md%deul_phi(s, x))
         case ('lag_S')
            call wr%write('lag_S', md%lag_S(s, x))
         case ('lag_L')
            call wr%write('lag_L', md%lag_L(s, x))
         case ('eul_P')
            call wr%write('eul_P', md%eul_P(s, x))
         case ('lag_P')
            call wr%write('lag_P', md%lag_P(s, x))
         case ('eul_rho')
            call wr%write('eul_rho', md%eul_rho(s, x))
         case ('lag_rho')
            call wr%write('lag_rho', md%lag_rho(s, x))
         case ('eul_T')
            call wr%write('eul_T', md%eul_T(s, x))
         case ('lag_T')
            call wr%write('lag_T', md%lag_T(s, x))
         case ('dE_dx')
            call wr%write('dE_dx', md%dE_dx(s, x))
         case ('dW_dx')
            call wr%write('dW_dx', md%dW_dx(s, x))
         case ('dC_dx')
            call wr%write('dC_dx', md%dC_dx(s, x))
         case ('F_j')
            call wr%write('F_j', md%F_j(s, x))
         case ('Yt_1')
            call wr%write('Yt_1', md%Yt_1(s, x))
         case ('Yt_2')
            call wr%write('Yt_2', md%Yt_2(s, x))
         case ('I_0')
            call wr%write('I_0', md%I_0(s, x))
         case ('I_1')
            call wr%write('I_1', md%I_1(s, x))
         case ('prop_type')
            call wr%write('prop_type', md%prop_type(s, x))
         case('freq_units')
            call wr%write('freq_units', ot_p%freq_units)
         case('freq_frame')
            call wr%write('freq_frame', ot_p%freq_frame)
         case default
            select type (ml => md%ml)
            type is (evol_model_t)
               call write_mode_evol_(ml)
               class default
               write(ERROR_UNIT, *) 'item:', TRIM(items(i))
               $ABORT(Invalid item in mode_item_list)
            end select
         end select

      end do item_loop

    end associate

    ! Close the file

    call wr%final()

    ! Finish

    return

  contains

    subroutine write_mode_evol_ (ml)

      type(evol_model_t), intent(in) :: ml
      
      ! Write the item

      associate (s => md%s, x => md%x)

        select case (items(i))
        case ('M_star')
           call wr%write('M_star', ml%M_star)
        case ('R_star')
           call wr%write('R_star', ml%R_star)
        case ('L_star')
           call wr%write('L_star', ml%L_star)
        case ('M_r')
           call wr%write('M_r', ml%M_r(s, x))
        case ('p')
           call wr%write('P', ml%P(s, x))
        case ('rho')
           call wr%write('rho', ml%rho(s, x))
        case ('T')
           call wr%write('T', ml%T(s, x))
        case default
           write(ERROR_UNIT, *) 'item:', TRIM(items(i))
           $ABORT(Invalid item)
        end select

      end associate

      ! Finish

      return

    end subroutine write_mode_evol_

  end subroutine write_mode

  !****

  function filter_mode_ (md, ot_p) result (filter_mode)

    type(mode_t), intent(in)    :: md
    type(out_par_t), intent(in) :: ot_p
    logical                     :: filter_mode

    character(LEN(ot_p%mode_filter_list)), allocatable :: filters(:)
    integer                                            :: i

    ! Decide whether to filter the mode

    filters = split_list(ot_p%mode_filter_list, ',')

    filter_mode = .FALSE.

    item_loop : do i = 1, SIZE(filters)

       select case (filters(i))
       case ('stable')
          filter_mode = filter_mode .OR. AIMAG(md%omega) <= 0._WP
       case ('unstable')
          filter_mode = filter_mode .OR. AIMAG(md%omega) > 0._WP
       case default
          $ABORT(Unrecognized filter in mode_filter_list)
       end select

    end do item_loop

    ! Finish

    return

  end function filter_mode_

  !****

  function subst_ (string, pattern, i, format) result (new_string)

    character(*), intent(in)  :: string
    character(*), intent(in)  :: pattern
    integer, intent(in)       :: i
    character(*), intent(in)  :: format
    character(:), allocatable :: new_string

    character(64) :: substring

    ! Write i into the substring buffer

    write(substring, format) i

    ! Do the replacement

    new_string = replace(string, pattern, TRIM(substring), every=.TRUE.)

    ! Finish

    return

  end function subst_

end module gyre_output