.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "MARIO_x86",0
area_width EQU 640
area_height EQU 480
area DD 0

foreground_width EQU 580
foreground_height EQU 120

counter_aux DD 0
counter DD 0 ; numara evenimentele de tip timer
score DD 0
coins DD 0
game_over DD 0
game_start DD 0
game_win DD 0
mario_x DD 160
mario_y DD 360
mario_orientation DD 0
mario_jumping DD 0
mario_jumping_up DD 0
walk_left DD 1
walk_right DD 1
count_jump DD 0
y_max DD 0
stage DD 0
dreapta_sus DD 1
dreapta_jos DD 1
stanga_jos DD 1
stanga_sus DD 1
sus_dreapta DD 1
sus_stanga DD 1
jos_dreapta DD 1
jos_stanga DD 1
jos DD 1
nofloating_right DD 0
nofloating_left DD 0

coin_stage1_1 DD 1
coin_stage1_2 DD 0
coin_stage2_1 DD 1
coin_stage2_2 DD 1

stage1_powerbrick DD 1

goomba1 DD 1
goomba1_x DD 600
goomba1_y DD 360
goomba1_o DD 1

goomba2 DD 1
goomba2_x DD 80
goomba2_y DD 360
goomba2_o DD 0

goomba3 DD 1
goomba3_x DD 400
goomba3_y DD 200
goomba3_o DD 1

bombshell_x DD 600
bombshell_y DD 120

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

format DB "%08x   ",0

symbol_width EQU 10
symbol_height EQU 20
mario_width EQU 40
mario_height EQU 40
include ..\res\digits.inc
include ..\res\letters.inc
include ..\res\mario.inc
include ..\res\background.inc
include ..\res\foreground.inc

.code
;int symbol, int* area 
draw_background proc
	push ebp
	mov ebp, esp
	pusha 
	mov eax, [ebp+arg1]
	lea esi, background
	mov ebx, area_width
	mul ebx
	mov ebx, area_height
	mul ebx
	shl eax, 2
	add esi, eax
	mov ecx, area_height
bucla_linii:
	mov edi, [ebp+arg2]
	mov eax, 0
	add eax, area_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, 0
	shl eax, 2
	add edi, eax
	push ecx
	mov ecx, area_width
bucla_coloane:
	mov eax, [esi]
	mov dword ptr[edi], eax
	add esi, 4
    add edi, 4
    loop bucla_coloane
    pop ecx
    loop bucla_linii
    popa
    mov esp, ebp
    pop ebp
    ret
draw_background endp

draw_background_macro macro symbol, drawArea
	push drawArea
	push symbol
	call draw_background
	add esp, 8
endm

draw_foreground proc ;functie pentru afisarea muntilor
    push ebp
    mov ebp, esp
    pusha
    mov eax, [ebp+arg1] ; citim simbolul de afisat
    lea esi, foreground
    mov ebx, foreground_width
    mul ebx
    mov ebx, foreground_height
    mul ebx
    shl eax, 2
    add esi, eax
    mov ecx, foreground_height
bucla_linii:
    mov edi, [ebp+arg2] ; pointer la matricea de pixeli
    mov eax, [ebp+arg4] ; pointer la coord y
    add eax, foreground_height
    sub eax, ecx
    mov ebx, area_width
    mul ebx
    add eax, [ebp+arg3] ; pointer la coord x
    shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
    add edi, eax
    push ecx
    mov ecx, foreground_width
bucla_coloane:
    mov eax, [esi]
	cmp eax, 003a9f4h
	je skip_pixel
    mov dword ptr [edi], eax
	skip_pixel:
    add esi, 4
    add edi, 4
    loop bucla_coloane
    pop ecx
    loop bucla_linii
    popa
    mov esp, ebp
    pop ebp
    ret
draw_foreground endp

draw_foreground_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call draw_foreground
	add esp, 16
endm

;(int symbol, int* area, int x, int y) 
draw_mario proc ;functie pentru afisarea caracterelor
    push ebp
    mov ebp, esp
    pusha
    mov eax, [ebp+arg1] ; citim simbolul de afisat
    lea esi, mario
    mov ebx, mario_width
    mul ebx
    mov ebx, mario_height
    mul ebx
    shl eax, 2
    add esi, eax
    mov ecx, mario_height
bucla_linii:
    mov edi, [ebp+arg2] ; pointer la matricea de pixeli
    mov eax, [ebp+arg4] ; pointer la coord y
    add eax, mario_height
    sub eax, ecx
    mov ebx, area_width
    mul ebx
    add eax, [ebp+arg3] ; pointer la coord x
    shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
    add edi, eax
    push ecx
    mov ecx, mario_height
bucla_coloane:
    mov eax, [esi]
	cmp eax, 003a9f4h
	je skip_pixel
    mov dword ptr [edi], eax
	skip_pixel:
    add esi, 4
    add edi, 4
    loop bucla_coloane
    pop ecx
    loop bucla_linii
    popa
    mov esp, ebp
    pop ebp
    ret
draw_mario endp

draw_mario_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call draw_mario
	add esp, 16
endm

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 27 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_background
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_background:
	mov dword ptr [edi], 003a9f4h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

make_stage_macro macro 
local stage1, final,powerbrick0_0,stage1_coins, stage1_powercoin, stage1_coin2
	draw_foreground_macro 0, area, 0, 0
	draw_foreground_macro 1, area, 0, 280
	
	cmp stage, 1
	je stage1
	
	
	draw_mario_macro 0,area, 320,360
	cmp stage1_powerbrick, 0
	je powerbrick0_0
	
	draw_mario_macro 4, area, 520, 120   ;5
	jmp stage1_coins
	
	powerbrick0_0:
	draw_mario_macro 5, area, 520, 120
	
	stage1_coins:
	cmp coin_stage1_1, 0
	je stage1_powercoin
	draw_mario_macro 3, area, 400, 360
	
	stage1_powercoin:
	cmp coin_stage1_2, 0
	je final
	draw_mario_macro 3, area, 520, 80
	jmp final
	
	stage1:
	cmp coin_stage2_1, 0
	je stage1_coin2
	draw_mario_macro 3, area, 80, 120
	
	stage1_coin2:
	cmp coin_stage2_2, 0
	je final
	draw_mario_macro 3, area, 120, 120
	
	
final:	
endm


make_writing_macro macro
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 600, 30
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 590, 30
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 580, 30
	
	mov eax, score
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 70, 30
	
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 60, 30

	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 50, 30
	
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 40, 30
	
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 30
	
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 30
	
	mov eax, coins
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 253, 30
	
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 243, 30
	
	;scriem un mesaj
	make_text_macro 'M', area, 20, 10
	make_text_macro 'A', area, 30, 10
	make_text_macro 'R', area, 40, 10
	make_text_macro 'I', area, 50, 10
	make_text_macro 'O', area, 60, 10
	
	make_text_macro 'X', area, 230, 30
	
	make_text_macro 'W', area, 370, 10
	make_text_macro 'O', area, 380, 10
	make_text_macro 'R', area, 390, 10
	make_text_macro 'L', area, 400, 10
	make_text_macro 'D', area, 410, 10
	
	make_text_macro '1', area, 380, 30
	make_text_macro '-', area, 390, 30
	make_text_macro '1', area, 400, 30

	make_text_macro 'T', area, 570, 10
	make_text_macro 'I', area, 580, 10
	make_text_macro 'M', area, 590, 10
	make_text_macro 'E', area, 600, 10
endm

draw_scene_macro macro
	make_stage_macro
	draw_mario_macro 2, area, 193, 20
	make_writing_macro
	make_enemies
	
endm

detect_collision macro
local begin_stage, dreapta_sus_check, dreapta_jos_check, stanga_sus_check, stanga_jos_check, sus_dreapta_check, sus_stanga_check, jos_dreapta_check, jos_stanga_check
	mov dreapta_sus, 1
	mov dreapta_jos, 1
	mov stanga_sus, 1
	mov stanga_jos, 1
	mov sus_dreapta, 1
	mov sus_stanga, 1
	mov jos_dreapta, 1
	mov jos_stanga, 1
	
	dreapta_sus_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		mov ecx, 2
		add ebx, ecx
		mul ebx
		mov ebx, mario_x
		add ebx, mario_width
		mov ecx, 4
		sub ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je dreapta_jos_check
		mov dreapta_sus, 0
		
		dreapta_jos_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		add ebx, mario_height
		mov ecx, 3
		sub ebx, ecx
		mul ebx
		mov ebx, mario_x
		add ebx, mario_width
		mov ecx, 4
		sub ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je stanga_sus_check
		mov dreapta_jos, 0
		
		stanga_sus_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		mov ecx, 2
		add ebx, ecx
		mul ebx
		mov ebx, mario_x
		mov ecx, 4
		add ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je stanga_jos_check
		mov stanga_sus, 0
		
		stanga_jos_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		add ebx, mario_height
		mov ecx, 3
		sub ebx, ecx
		mul ebx
		mov ebx, mario_x
		mov ecx, 4
		add ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je sus_dreapta_check
		mov stanga_jos, 0
		
		sus_dreapta_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		mov ecx, 2
		sub ebx, ecx
		mul ebx
		mov ebx, mario_x
		add ebx, mario_width
		mov ecx, 3
		sub ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je sus_stanga_check
		mov sus_dreapta, 0
		
		sus_stanga_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		mov ecx, 2
		sub ebx, ecx
		mul ebx
		mov ebx, mario_x
		mov ecx, 4
		add ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je jos_dreapta_check
		mov sus_stanga, 0
		
		jos_dreapta_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		add ebx, mario_height
		mov ecx, 2
		add ebx, ecx
		mul ebx
		mov ebx, mario_x
		add ebx, mario_width
		mov ecx, 6
		sub ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je jos_stanga_check
		mov jos_dreapta, 0
		
		jos_stanga_check:
		mov esi, area
		mov eax, area_width
		mov ebx, mario_y
		;add ebx, mario_height
		add ebx, mario_height
		mov ecx, 2
		add ebx, ecx
		mul ebx
		mov ebx, mario_x
		mov ecx, 6
		add ebx, ecx
		add eax, ebx
		shl eax, 2
		add esi, eax
		;mov dword ptr[esi], 0000000h
		mov eax, [esi]
		mov ebx, eax
		push eax
		push edx
		push ecx
		push ebx
		push offset format
		call printf
		add esp, 8
		pop ecx
		pop edx
		pop eax
	
		cmp eax, 0003a9f4h
		je final_collision
		mov jos_stanga, 0

final_collision:
	mov ebx, jos_dreapta
	mov ecx, jos_stanga
	and ebx, ecx
	mov jos, ebx	
endm

reinitialize macro

mov counter_aux, 0
mov counter, 0
mov score, 0
mov coins, 0
mov game_over, 0
mov game_start, 1
mov game_win, 0
mov mario_x, 160
mov mario_y, 360
mov mario_orientation, 0
mov mario_jumping, 0
mov mario_jumping_up, 0
mov walk_left, 1
mov walk_right, 1
mov count_jump, 0
mov y_max, 0
mov stage, 0
mov dreapta_sus, 1
mov dreapta_jos, 1
mov stanga_jos, 1
mov stanga_sus, 1
mov sus_dreapta, 1
mov sus_stanga, 1
mov jos_dreapta, 1
mov jos_stanga, 1
mov jos, 1
mov nofloating_right, 0
mov nofloating_left, 0
mov coin_stage1_1, 1
mov coin_stage1_2, 0
mov coin_stage2_1, 1
mov coin_stage2_2, 1
mov stage1_powerbrick, 1
mov goomba1, 1
mov goomba1_x, 600
mov goomba1_y, 360
mov goomba1_o, 1
mov goomba2, 1
mov goomba2_x, 80
mov goomba2_y, 360
mov goomba2_o, 1
mov goomba3, 1
mov goomba3_x, 400
mov goomba3_y, 200
mov goomba3_o, 1
mov bombshell_x, 600
mov bombshell_y, 120

endm

make_enemies macro
local enemies_stage1, gmb1, gmb1_2, gmb2_2, gmb3, gmb3_2, bmbshll, final
	cmp stage, 1
	je enemies_stage1
	gmb1:
	cmp goomba1, 0
	je final
	cmp counter_aux, 10
	jge gmb1_2
	draw_mario_macro 14, area, goomba1_x, goomba1_y
	jmp final
	gmb1_2:
	draw_mario_macro 15, area, goomba1_x, goomba1_y
	jmp final
	
	enemies_stage1:
	cmp goomba2, 0
	je gmb3
	cmp counter_aux, 10
	jge gmb2_2
	draw_mario_macro 15, area, goomba2_x, goomba2_y
	jmp gmb3
	gmb2_2:
	draw_mario_macro 14, area, goomba2_x, goomba2_y
	
	gmb3:
	cmp goomba3, 0
	je bmbshll
	cmp counter_aux, 10
	jge gmb3_2
	draw_mario_macro 14, area, goomba3_x, goomba3_y
	jmp bmbshll
	gmb3_2:
	draw_mario_macro 15, area, goomba3_x, goomba3_y
	
	bmbshll:
	draw_mario_macro 17, area, bombshell_x, bombshell_y
	
	
final:
endm


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	mov ecx, eax
	mov eax, area
		
	jmp afisare_scenariu
	
evt_click:
	mov eax, [ebp+arg2]		;x
	mov ebx, [ebp+arg3]		;y
	
	game_win_etq:
	cmp game_win, 0
	je game_over_etq			;240, 320 			400,380
	mov ecx, 240
	cmp eax, ecx
	jl gamewin_exit
	mov ecx, 400
	cmp eax, ecx
	jg gamewin_exit
	mov ecx, 320
	cmp ebx, ecx
	jl gamewin_exit
	mov ecx, 380
	cmp ebx, ecx
	jg gamewin_exit
	reinitialize
	jmp final_draw
	
	gamewin_exit:			;260, 400			380, 450
	mov ecx, 260
	cmp eax, ecx
	jl final_draw
	mov ecx, 380
	cmp eax, ecx
	jg final_draw
	mov ecx, 400
	cmp ebx, ecx
	jl final_draw
	mov ecx, 450
	cmp ebx, ecx
	jg final_draw
	call exit
	jmp final_draw
	
	game_over_etq:
	cmp game_over, 0			; 260, 370       380, 420       
	je game_start_etq
	mov ecx, 260
	cmp eax, ecx
	jl final_draw
	mov ecx, 380
	cmp eax, ecx
	jg final_draw
	mov ecx, 370
	cmp ebx, ecx
	jl final_draw
	mov ecx, 420
	cmp ebx, ecx
	jg final_draw
	reinitialize
	jmp final_draw
	
	game_start_etq:
	cmp game_start, 0			;x:250, y:280      x:390, y:340
	jne evt_timer
	mov ecx, 250
	cmp eax, ecx
	jl titlescreen_exit
	mov ecx, 390
	cmp eax, ecx
	jg titlescreen_exit
	mov ecx, 280
	cmp ebx, ecx
	jl titlescreen_exit
	mov ecx, 340
	cmp ebx, ecx
	jg titlescreen_exit
	mov game_start, 1
	jmp final_draw
	
	titlescreen_exit:			;x: 260, y: 380      x:380, y: 420
	mov ecx, 260
	cmp eax, ecx
	jl final_draw
	mov ecx, 380
	cmp eax, ecx
	jg final_draw
	mov ecx, 380
	cmp ebx, ecx
	jl final_draw
	mov ecx, 420
	cmp ebx, ecx
	jg final_draw
	call exit
	jmp final_draw
	
	
evt_timer:
	inc counter_aux
	cmp counter_aux, 20
	jne bmbshll
	mov counter_aux, 0
	inc counter
	gmb1:
	cmp goomba1_x, 600
	je gmb1_o_left
	cmp goomba1_x, 360
	je gmb1_o_right
	jmp gmb1_move
	gmb1_o_left:
	mov goomba1_o, 1
	jmp gmb1_move
	gmb1_o_right:
	mov goomba1_o, 0
	gmb1_move:
	cmp goomba1_o, 0
	jne gmb1_moveleft
	mov ebx, goomba1_x
	add ebx, symbol_width
	mov goomba1_x, ebx
	jmp gmb2
	gmb1_moveleft:
	mov ebx, goomba1_x
	sub ebx, symbol_width
	mov goomba1_x, ebx				;480-80			y:260,   x: 400-240
	
	gmb2:
	cmp goomba2_x, 80
	je gmb2_o_right
	cmp goomba2_x, 480
	je gmb2_o_left
	jmp gmb2_move
	gmb2_o_right:
	mov goomba2_o, 0
	jmp gmb2_move
	gmb2_o_left:
	mov goomba2_o, 1
	gmb2_move:
	cmp goomba2_o, 0
	jne gmb2_moveleft
	mov ebx, goomba2_x
	add ebx, symbol_width
	mov goomba2_x, ebx
	jmp gmb3
	gmb2_moveleft:
	mov ebx, goomba2_x
	sub ebx, symbol_width
	mov goomba2_x, ebx
	
	gmb3:
	cmp goomba3_x, 240
	je gmb3_o_right
	cmp goomba3_x, 400
	je gmb3_o_left
	jmp gmb3_move
	gmb3_o_right:
	mov goomba3_o, 0
	jmp gmb3_move
	gmb3_o_left:
	mov goomba3_o, 1
	gmb3_move:
	cmp goomba3_o, 0
	jne gmb3_moveleft
	mov ebx, goomba3_x
	add ebx, symbol_width
	mov goomba3_x, ebx
	jmp bmbshll
	gmb3_moveleft:
	mov ebx, goomba3_x
	sub ebx, symbol_width
	mov goomba3_x, ebx
	jmp afisare_scenariu
	
	bmbshll:
	cmp counter_aux, 2
	je cmpbombshell
	cmp counter_aux, 4
	je cmpbombshell
	cmp counter_aux, 6
	je cmpbombshell
	cmp counter_aux, 8
	je cmpbombshell
	cmp counter_aux, 10
	je cmpbombshell
	cmp counter_aux, 12
	je cmpbombshell
	cmp counter_aux, 14
	je cmpbombshell
	cmp counter_aux, 16
	je cmpbombshell
	cmp counter_aux, 18
	je cmpbombshell
	cmp counter_aux, 0
	je cmpbombshell
	jmp afisare_scenariu
	cmpbombshell:
	cmp bombshell_x, 0
	jne move_bombshell
	mov bombshell_x, 600
	move_bombshell:
	mov ebx, bombshell_x
	sub ebx, symbol_width
	mov bombshell_x, ebx
	
afisare_scenariu:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	;
	;cmp game_start, 1
	;je draw_level
	
	
 	
draw_level: 
	win_condition:
	cmp stage, 0
	je lose_condition
	cmp mario_x, 580
	jl lose_condition
	cmp mario_y, 280
	jg lose_condition
	mov game_over, 0
	mov game_start, 0
	mov game_win, 1
	jmp check_gamestate
	
	lose_condition:
	cmp stage, 0
	jne lose_condition1
	cmp goomba1, 0
	je check_gamestate
	mov eax, goomba1_x
	sub eax, mario_x
	cmp eax, 20
	ja check_gamestate
	mov eax, goomba1_y
	sub eax, mario_y
	cmp eax, 30
	jl death
	jg check_gamestate
	mov goomba1, 0
	mov eax, score
	mov ebx, 200
	add eax, ebx
	mov score, eax
	jmp check_gamestate
	
	lose_condition1:
	cmp goomba2, 0
	je lose_condition2
	mov eax, goomba2_x
	sub eax, mario_x
	cmp eax, 20
	ja lose_condition2
	mov eax, goomba2_y
	sub eax, mario_y
	cmp eax, 30
	jl death
	jg lose_condition2
	mov goomba2, 0
	mov eax, score
	mov ebx, 200
	add eax, ebx
	mov score, eax
	
	lose_condition2:
	cmp goomba3, 0
	je lose_condition3
	mov eax, goomba3_x
	sub eax, mario_x
	cmp eax, 20
	ja lose_condition3
	cmp mario_y, 160
	jl lose_condition3
	cmp mario_y, 240
	jg lose_condition3
	mov eax, goomba3_y
	sub eax, mario_y
	cmp eax, 30
	jl death
	jg lose_condition3
	mov goomba3, 0
	mov eax, score
	mov ebx, 200
	add eax, ebx
	mov score, eax
	
	lose_condition3:
	mov eax, bombshell_x
	sub eax, mario_X
	cmp eax, 30
	ja check_gamestate
	mov eax, mario_y
	sub eax, bombshell_y
	cmp eax, 40
	jg check_gamestate
	mov eax, bombshell_y
	sub eax, mario_y
	cmp eax, 40
	jg check_gamestate
	
	death:
	mov game_start, 0
	mov game_over, 1
	
	check_gamestate:
	cmp game_start, 1
	je draw_gamestart
	cmp game_over, 1
	je draw_gameover
	cmp game_win, 1
	je draw_gamewin
	
	draw_background_macro 2, area
	jmp final_draw
	
	draw_gameover:
	draw_background_macro 3, area
	jmp final_draw
	
	draw_gamewin:
	draw_background_macro 4, area
	jmp final_draw
	
	draw_gamestart:
	
	out_of_bounds:
	cmp mario_y, 20
	jg unstuck
	mov mario_y, 20
	unstuck:
	cmp mario_y, 370
	jl continue_gamestart
	mov mario_y, 360
	
	continue_gamestart:
	cmp stage, 0
	jne prev_stage
	cmp mario_x, 600
	jle no_wraparound
	mov mario_x, 20
	mov mario_y, 360
	mov stage, 1
	jmp stage_coins
	prev_stage:
		cmp mario_x, 10
		jg stage_coins
		mov mario_x, 600
		mov mario_y, 360
		mov stage, 0
		jmp stage_coins
	no_wraparound:
		cmp mario_x, 0
		jg stage_coins
		mov mario_x, 0
	
	stage_coins:
	cmp stage, 1
	je coins1
	cmp coin_stage1_1, 0
	je powerbrick_stage1
	cmp mario_x, 410
	jne powerbrick_stage1
	mov ecx, 360
	sub ecx, mario_y
	cmp ecx, 30
	jg powerbrick_stage1
	mov coin_stage1_1, 0
	inc coins
	push ebx
	mov ebx, score
	add ebx, 100
	mov score, ebx
	pop ebx
	jmp powerbrick_stage1
	
	coins1:
	cmp coin_stage2_1, 0
	je coins1_2
	cmp mario_x, 100
	jne coins1_2
	cmp mario_y, 120
	jg scene
	cmp mario_y, 110
	jl scene
	mov coin_stage2_1, 0
	inc coins
	push ebx
	mov ebx, score
	add ebx, 100
	mov score, ebx
	pop ebx
	coins1_2:
	cmp coin_stage2_2, 0
	je scene
	cmp mario_x, 140
	jne scene
	cmp mario_y, 120
	jg scene
	cmp mario_y, 110
	jl scene
	mov coin_stage2_2, 0
	inc coins
	push ebx
	mov ebx, score
	add ebx, 100
	mov score, ebx
	pop ebx
	jmp scene
	
	powerbrick_stage1:
	cmp stage1_powerbrick, 0
	je powerbrick_coin1
	cmp mario_x, 500
	jl powerbrick_coin1
	cmp mario_x, 550
	jg powerbrick_coin1
	cmp mario_y, 160
	jne powerbrick_coin1
	mov stage1_powerbrick, 0
	mov coin_stage1_2, 1
	
	powerbrick_coin1:
	cmp coin_stage1_2, 0
	je scene
	cmp mario_x, 520	
	jne scene
	cmp mario_y, 60
	jle scene
	cmp mario_y, 80
	jg scene
	mov ecx, 100
	add ecx, score
	mov score, ecx
	inc coins
	mov coin_stage1_2, 0
	
	
	

	scene:
	draw_background_macro stage, area
	make_enemies
	detect_collision
	draw_scene_macro
	
	cmp nofloating_left, 1
	je falldown_left
	cmp nofloating_right, 1
	je falldown_right
	
	is_mario_jumping:
	cmp mario_jumping, 1
	je jumping_loop
	cmp mario_jumping_up, 1
	je jumping_up_loop
	
	cmp mario_orientation, 0
	jne idle_left
	draw_mario_macro 6, area, mario_x, mario_y
	jmp keyboard_event
	idle_left:
		draw_mario_macro 7, area, mario_x, mario_y
		jmp keyboard_event
	
	falldown_left:
	cmp jos, 1
	je still_falling_left
	mov nofloating_left, 0
	draw_mario_macro 7, area, mario_x, mario_y
	jmp final_draw
still_falling_left:
	mov ecx, mario_y
	add ecx, symbol_width
	mov mario_y, ecx
	draw_mario_macro 13, area, mario_x, mario_y
	jmp final_draw
	
	falldown_right:
	cmp jos, 1
	je still_falling_right
	mov nofloating_right, 0
	draw_mario_macro 6, area, mario_x, mario_y
	jmp final_draw
still_falling_right:
	mov ecx, mario_y
	add ecx, symbol_width
	mov mario_y, ecx
	draw_mario_macro 12, area, mario_x, mario_y
	jmp final_draw	
	
	jumping_loop:
		cmp mario_orientation, 1
		je jumping_left
		
		draw_scene_macro
		
		cmp y_max, 1
		je falling_right
		jumping_right:
			cmp sus_dreapta, 0
			jne jumping_right_check2
			mov y_max, 1
			jmp final_draw
			
			jumping_right_check2:
			cmp sus_stanga, 1
			je ok_jump_right
			mov y_max, 1
			jmp final_draw
		
		ok_jump_right:
		mov ebx, mario_y
		sub ebx, 10
		mov mario_y, ebx
		
		cmp dreapta_sus, 0
		je just_jump_right
		cmp dreapta_jos, 0
		je just_jump_right
		
		mov ebx, mario_x
		add ebx, 10
		mov mario_x, ebx
		
		just_jump_right:
		draw_mario_macro 12, area, mario_x, mario_y
		inc count_jump
		cmp count_jump, 12
		jne final_draw
		mov y_max, 1
		jmp final_draw
			
		falling_right:
			cmp jos_stanga, 1
			je falling_right_check2
			mov y_max, 0
			mov count_jump, 0
			mov mario_jumping, 0
			jmp final_draw
			
			falling_right_check2:
			cmp jos_dreapta, 1
			je ok_falling_right
			mov y_max, 0
			mov count_jump, 0
			mov mario_jumping, 0
			jmp final_draw
			
			ok_falling_right:
			mov ebx, mario_y
			add ebx, 10
			mov mario_y, ebx
			
			cmp dreapta_sus, 0
			je just_fall_right
			cmp dreapta_jos, 0
			je just_fall_right
			
			mov ebx, mario_x
			add ebx, 10
			mov mario_x, ebx
			
			just_fall_right:
			draw_mario_macro 12, area, mario_x, mario_y
			jmp final_draw	
			
		jumping_left:
			draw_scene_macro
			cmp y_max, 1
			je falling_left
			
			cmp sus_dreapta, 0
			jne jumping_left_check2
			mov y_max, 1
			jmp final_draw
			
			jumping_left_check2:
			cmp sus_stanga, 1
			je ok_jump_left
			mov y_max, 1
			jmp final_draw
			
			ok_jump_left:
			mov ebx, mario_y
			sub ebx, 10
			mov mario_y, ebx
			
			cmp stanga_sus, 0
			je just_jump_left
			cmp stanga_jos, 0
			je just_jump_left
			
			mov ebx, mario_x
			sub ebx, 10
			mov mario_x, ebx
			
		just_jump_left:
			draw_mario_macro 13, area, mario_x, mario_y
			inc count_jump
			cmp count_jump, 12
			jne final_draw
			mov y_max, 1
			jmp final_draw
			
		falling_left:
			cmp jos_dreapta, 1
			je falling_left_check2
			mov y_max, 0
			mov count_jump, 0
			mov mario_jumping, 0
			jmp final_draw
			
			falling_left_check2:
			cmp jos_stanga, 1
			je ok_falling_left
			mov y_max, 0
			mov count_jump, 0
			mov mario_jumping, 0
			jmp final_draw
			
			ok_falling_left:
			mov ebx, mario_y
			add ebx, 10
			mov mario_y, ebx
			
			cmp stanga_sus, 0
			je just_fall_left
			cmp stanga_jos, 0
			je just_fall_left
			
			mov ebx, mario_x
			sub ebx, 10
			mov mario_x, ebx
			
			just_fall_left:
			draw_mario_macro 13, area, mario_x, mario_y
			jmp final_draw
			
			
	jumping_up_loop:
		draw_scene_macro
		cmp y_max, 1
		je falling_down
			cmp sus_dreapta, 0
			jne jumping_up_check2
			mov y_max, 1
			jmp final_draw
			
			jumping_up_check2:
			cmp sus_stanga, 1
			je ok_jump_up
			mov y_max, 1
			jmp final_draw
			
			ok_jump_up:
			mov ebx, mario_y
			sub ebx, 10
			mov mario_y, ebx
			cmp mario_orientation, 1
			je j_look_left
				draw_mario_macro 12, area, mario_x, mario_y
				jmp j_finishDraw
			j_look_left:
				draw_mario_macro 13, area, mario_x, mario_y
			j_finishDraw:
			inc count_jump
			cmp count_jump, 12
			jne final_draw
			mov y_max, 1
			jmp final_draw
			
			falling_down:
			cmp count_jump, 0
			jne ok_falling_down
			mov y_max, 0
			mov mario_jumping_up, 0
			jmp final_draw
			
			ok_falling_down:
			mov ebx, mario_y
			add ebx, 10
			mov mario_y, ebx
			dec count_jump
			cmp mario_orientation, 1
			je f_look_left
				draw_mario_macro 12, area, mario_x, mario_y
				jmp f_finishDraw
			f_look_left:
				draw_mario_macro 13, area, mario_x, mario_y
			f_finishDraw:
			jmp final_draw

	keyboard_event:
	mov ECX, 0
	mov EAX, [EBP+arg2]
	cmp EAX, 'D'
	je move_right
	cmp EAX, 'A'
	je move_left
	cmp EAX, ' '
	je jump
	cmp EAX, 'W'
	je jump_up
	;cmp EAX, 'Z'
	;je do_gameover
	;cmp EAX, 'X'
	;je do_gamewin
	jmp final_draw
	
move_right:
		draw_scene_macro
		cmp dreapta_sus, 0
		je move_right_draw
		mov EBX, mario_x
		add EBX, 5
		mov mario_X, EBX
	move_right_draw:
		draw_mario_macro 8, area, mario_x, mario_y
		mov mario_orientation, 0
		cmp jos, 0
		je final_draw
		mov nofloating_right, 1
		jmp final_draw
	
move_left:
		draw_scene_macro
		cmp stanga_sus, 0
		je move_left_draw
		mov EBX, mario_x
		sub EBX, 5
		mov mario_x, EBX
	move_left_draw:
		draw_mario_macro 10, area, mario_x, mario_y
		mov mario_orientation, 1
		cmp jos, 0
		je final_draw
		mov nofloating_left, 1
		jmp final_draw
	
	jump:
		mov mario_jumping, 1
		jmp final_draw
	
	jump_up:
		mov mario_jumping_up, 1
		jmp final_draw
	; do_gameover:
		; mov game_over, 1
		; mov game_start, 0
		; mov game_win, 0
		; jmp final_draw
	; do_gamewin:
		; mov game_over, 0
		; mov game_start, 0
		; mov game_win, 1
		; jmp final_draw
	
final_draw:
	
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start