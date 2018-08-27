! This Source Code Form is subject to the terms of the Mozilla Public
! License, v. 2.0. If a copy of the MPL was not distributed with this
! file, You can obtain one at http://mozilla.org/MPL/2.0/.
module mbd_gradients_type

use mbd_constants

implicit none

private
public :: mbd_gradients, mbd_grad_matrix_real, mbd_grad_matrix_complex, &
    mbd_grad_switch, mbd_grad_scalar, damping_grad, op1minus_grad

type :: mbd_gradients
    real(dp), allocatable :: dcoords(:, :)  ! n_atoms by 3
    real(dp), allocatable :: dalpha(:)
    real(dp), allocatable :: dalpha_dyn(:, :)  ! n_atoms by 0:n_freq
    real(dp), allocatable :: dC6(:)
    real(dp), allocatable :: dr_vdw(:)
    real(dp), allocatable :: domega(:)
    real(dp), allocatable :: dV(:)
    real(dp), allocatable :: dV_free(:)
    real(dp), allocatable :: dX_free(:)
end type

type :: mbd_grad_switch
    logical :: dcoords = .false.
    logical :: dalpha = .false.
    logical :: dalpha_dyn = .false.
    logical :: dC6 = .false.
    logical :: dr_vdw = .false.
    logical :: domega = .false.
    logical :: dsigma = .false.
    logical :: dV = .false.
    logical :: dV_free = .false.
    logical :: dX_free = .false.
    contains
    procedure :: any => mbd_grad_switch_any
end type

type :: mbd_grad_matrix_real
    real(dp), allocatable :: dr(:, :, :)
    real(dp), allocatable :: dvdw(:, :)
    real(dp), allocatable :: dsigma(:, :)
end type

type :: mbd_grad_matrix_complex
    complex(dp), allocatable :: dr(:, :, :)
    complex(dp), allocatable :: dvdw(:, :)
    complex(dp), allocatable :: dsigma(:, :)
end type

type :: mbd_grad_scalar
    real(dp), allocatable :: dr(:)  ! explicit derivative
    real(dp), allocatable :: dvdw
end type

contains

logical function mbd_grad_switch_any(this) result(any)
    class(mbd_grad_switch), intent(in) :: this

    any = this%dcoords .or. this%dalpha .or. this%dC6 .or. &
        this%dr_vdw .or. this%domega
end function

function damping_grad(f, df, T, dT, dfT, grad) result(fT)
    real(dp), intent(in) :: f
    type(mbd_grad_scalar), intent(in) :: df
    real(dp), intent(in) :: T(3, 3)
    type(mbd_grad_matrix_real), intent(in) :: dT
    type(mbd_grad_matrix_real), intent(out) :: dfT
    type(mbd_grad_switch), intent(in) :: grad
    real(dp) :: fT(3, 3)

    integer :: c

    fT = f*T
    if (grad%dcoords) then
        allocate (dfT%dr(3, 3, 3), source=0d0)
        if (allocated(df%dr)) forall (c = 1:3) dfT%dr(:, :, c) = df%dr(c)*T
        if (allocated(dT%dr)) dfT%dr = dfT%dr + f*dT%dr
    end if
    if (grad%dr_vdw) then
        allocate (dfT%dvdw(3, 3), source=0d0)
        if (allocated(df%dvdw)) dfT%dvdw = df%dvdw*T
        if (allocated(dT%dvdw)) dfT%dvdw = dfT%dvdw + f*dT%dvdw
    end if
    if (grad%dsigma) dfT%dsigma = f*dT%dsigma
end function

subroutine op1minus_grad(f, df)
    real(dp), intent(inout) :: f
    type(mbd_grad_scalar), intent(inout) :: df

    f = 1-f
    if (allocated(df%dr)) df%dr = -df%dr
    if (allocated(df%dvdw)) df%dvdw = -df%dvdw
end subroutine

end module
