; Cuckoo Sandbox - Automated Malware Analysis.
; Copyright (C) 2010-2014 Cuckoo Foundation.
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

%ifndef tramp_special
global _asm_tramp
global _asm_tramp_size
global _asm_tramp_hook_alloc_off
global _asm_tramp_hook_handler_off
global _asm_tramp_orig_func_stub_off
global _asm_tramp_retaddr_off
global _asm_tramp_retaddr_add_off
global _asm_tramp_stack_displacement_off
%else
global _asm_tramp_special
global _asm_tramp_special_size
global _asm_tramp_special_hook_alloc_off
global _asm_tramp_special_hook_handler_off
global _asm_tramp_special_orig_func_stub_off
global _asm_tramp_special_retaddr_off
global _asm_tramp_special_retaddr_add_off
global _asm_tramp_special_stack_displacement_off
%endif

%define TLS_HOOK_INFO 0x44
%define TLS_TEMPORARY 0x48
%define TLS_LASTERR 0x34

%define HOOKCNT_OFF 0
%define LASTERR_OFF 4
%define STCKVAL_OFF 8

asm_tramp:

    ; fetch hook-info
    mov eax, dword [fs:TLS_HOOK_INFO]
    jmp _tramp_addresses

_tramp_hook_alloc:
    dd 0xcccccccc

_tramp_hook_handler:
    dd 0xcccccccc

_tramp_orig_func_stub:
    dd 0xcccccccc

_tramp_retaddr:
    dd 0xcccccccc

_tramp_retaddr_add:
    dd 0xcccccccc

_tramp_stack_displacement_off:
    dd 0xcccccccc

_tramp_addresses:

    test eax, eax
    jnz _tramp_check_count

    ; create hook-info
    call _tramp_getpc

_tramp_getpc:
    pop eax

    pushad
    call dword [eax+_tramp_hook_alloc-_tramp_getpc]
    popad

    mov dword [fs:TLS_TEMPORARY], eax
    mov eax, dword [fs:TLS_HOOK_INFO]

    ; do a backup of the stack contents before they're overwritten
    pop dword [eax+STCKVAL_OFF]
    pop dword [eax+STCKVAL_OFF+4]
    pop dword [eax+STCKVAL_OFF+8]
    pop dword [eax+STCKVAL_OFF+12]

    mov eax, dword [fs:TLS_TEMPORARY]

    ; adjust for any pushes to the stack that may have already happened
    sub esp, dword [eax+_tramp_stack_displacement_off-_tramp_getpc]

    mov eax, dword [fs:TLS_HOOK_INFO]

_tramp_check_count:

%ifndef tramp_special

    cmp dword [eax+HOOKCNT_OFF], 0
    jz _tramp_do_it

    ; we're already in a hook - abort
    call _tramp_getpc2

_tramp_getpc2:
    pop eax

    ; jump to the original function stub
    jmp dword [eax+_tramp_orig_func_stub-_tramp_getpc2]

%endif

_tramp_do_it:

    ; increase hook count
    inc dword [eax+HOOKCNT_OFF]

    ; save last error
    push dword [fs:TLS_LASTERR]
    pop dword [eax+LASTERR_OFF]

    call _tramp_getpc3

_tramp_getpc3:
    pop eax

    ; save the return address
    pushad
    push dword [esp+32]
    call dword [eax+_tramp_retaddr_add-_tramp_getpc3]
    popad

    ; fetch the new return address
    push dword [eax+_tramp_retaddr-_tramp_getpc3]

    ; actually patch the return address
    pop dword [esp]

    ; jump to the hook handler
    jmp dword [eax+_tramp_hook_handler-_tramp_getpc3]

_tramp_end:


%ifndef tramp_special
_asm_tramp dd asm_tramp
_asm_tramp_size dd _tramp_end - asm_tramp
_asm_tramp_hook_alloc_off dd _tramp_hook_alloc - asm_tramp
_asm_tramp_hook_handler_off dd _tramp_hook_handler - asm_tramp
_asm_tramp_orig_func_stub_off dd _tramp_orig_func_stub - asm_tramp
_asm_tramp_retaddr_off dd _tramp_retaddr - asm_tramp
_asm_tramp_retaddr_add_off dd _tramp_retaddr_add - asm_tramp
_asm_tramp_stack_displacement_off dd \
    _tramp_stack_displacement_off - asm_tramp
%else
_asm_tramp_special dd asm_tramp
_asm_tramp_special_size dd _tramp_end - asm_tramp
_asm_tramp_special_hook_alloc_off dd _tramp_hook_alloc - asm_tramp
_asm_tramp_special_hook_handler_off dd _tramp_hook_handler - asm_tramp
_asm_tramp_special_orig_func_stub_off dd _tramp_orig_func_stub - asm_tramp
_asm_tramp_special_retaddr_off dd _tramp_retaddr - asm_tramp
_asm_tramp_special_retaddr_add_off dd _tramp_retaddr_add - asm_tramp
_asm_tramp_special_stack_displacement_off dd \
    _tramp_stack_displacement_off - asm_tramp
%endif
