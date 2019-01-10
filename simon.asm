; Juego de memoria Simon

org 100h

; pantalla de inicio e instrucciones
mov ah,0h
mov al,03h
int 10h

mov ah,02h  ; coloca cursor
mov dh,3    ; fila
mov dl,28   ; col
mov bh,0
int 10h
mov ah,09   ; imprime cadena hasta encontrar $
mov dx, offset msjtitulo
int 21h

mov ah,02h
mov dh,6
mov dl,19
mov bh,0
int 10h
mov ah,09
mov dx, offset msjInstrucciones
int 21h

mov ah,02h
mov dh,9
mov dl,19
mov bh,0
int 10h
mov ah,09
mov dx, offset msjTeclas
int 21h

mov si, offset msjTColor ; por medio de un loop muestra las teclas
mov cx, 10
mostrar_teclas:
    mov ah,02h
    mov dh,cl   ; fila
    mov dl,22   ; col
    mov bh,0
    int 10h

    xor ax,ax
    mov ah,09h
    mov dx, [si]
    int 21h

    add si,2
    inc cx            ; inicia en fila 10 se suma 1 cada ciclo
    cmp cl,15         ; comprueba si aun faltan (10+5teclas = 15)
    jne mostrar_teclas

mov ah,02h
mov dh,22
mov dl,28
mov bh,0
int 10h
mov ah,09
mov dx, offset msjPIniciar
int 21h


esp_enter:           ; espera hasta presionar la tecla enter
mov ah,00h
int 16h
cmp al, 0dh
jne esp_enter

; inicio del juego
mov ax,1003h         ; modo pantalla para cancelar blink de texto
mov bx,0
int 10h

mov ah,6             ; limpia pantalla
xor al,al
xor cx,cx
mov dx,184fh
mov bh,13
int 10h

mov ch,32            ; ocultar cursor
mov ah,1
int 10h

call verdeObscuro    ; dibuja los cuadros
call rojoObscuro
call azulObscuro
call amarillo

; ciclo del juego
juego:                       ; ciclo que controla la repeticion de las secuencias y captura de teclas
    inc pasada               ; contador de los ciclos para reproducir la secuencia hasta ese numero
    mov si, offset nivel1    ; SI apuntara a un arreglo con la secuencia
    mov cx, 0
    mostrar:                 ; loop para mostrar las secuencias
        mov al,[si]
        call dibsonar        ; procedimiento dibuja y toca una nota
        inc si               ; siguiente nota
        inc cx
        cmp cx,pasada        ; si el contador aun no llega al numero de pasadas reproduce la siguiente
        jb mostrar

    mov si, offset nivel1
    mov cx,0                 ; ciclo para introducir la secuencia de teclas
    revisa_key:
        push cx

        mov ah,07h           ; espera la presion de una tecla
        int 21h              ; devuelve en al la tecla

        call dibsonar

        cmp al,1bh           ; ESC salir
        jne noESC
        jmp salir
        noESC:

        cmp al,[si]          ; comparar tecla con la presente en el arreglo
        jne incorrecta       ; si es diferente termina el juego
        inc si               ; si fue igual avanza a la siguiente

        pop cx
        inc cx
        cmp cx,pasada        ; repite el ciclo para capturar la siguiente tecla
        jb revisa_key


        cmp [si],'$'         ; si se llego al final de la secuencia
        je fin_nivel         ; da por terminado el juego y el jugador es ganador
        jmp juego            ; sino regresa para reproducir la siguiente secuencia


incorrecta:                  ; muestra mensaje perder
    mov ah,02h
    mov dh,3    ; fila
    mov dl,36   ; col
    mov bh,0
    int 10h

    mov ah,09
    mov dx, offset msjPerdiste
    int 21h
    jmp salir

fin_nivel:                  ; muestra mensaje ganar
    mov ah,02h
    mov dh,3
    mov dl,36
    mov bh,0
    int 10h

    mov ah,09
    mov dx, offset msjGanaste
    int 21h

salir:
    mov ah,02h
    mov dh,18
    mov dl,23
    mov bh,0
    int 10h

    mov ah, 09h             ; muestra instrucciones para salir
    mov dx, offset msjSalir
    int 21h

    espera_enter:
    mov ah,00h
    int 16h
    cmp al, 0dh
    jne espera_enter

    mov ax, 0003h  ; cambia a la configuracion normal de pantalla (texo 80*25)
    int 10h
    mov ax, 4c00h  ; equivalente al return 0 en c para evitar problemas en DOSBox
    int 21h

; dibuja la tecla y reproduce su nota
; espera en 'al' la tecla
proc dibsonar
    push ax

    cmp al,'q'          ; verde
    jne noVe
    call verdeBrillante
    mov bx,5709         ; frecuencia para nota
    call play_nota
    call verdeObscuro
    jmp tecla_procesada
    noVe:

    cmp al,'w'          ; rojo
    jne noRo
    call rojoBrillante
    mov bx,4870
    call play_nota
    call rojoObscuro
    jmp tecla_procesada
    noRo:

    cmp al,'a'          ; azul
    jne noAz
    call azulBrillante
    mov bx,2875
    call play_nota
    call azulObscuro
    jmp tecla_procesada
    noAz:

    cmp al,'s'          ; amarillo
    jne noAm
    call blanco
    mov bx,3837
    call play_nota
    call amarillo
    jmp tecla_procesada
    noAm:
    tecla_procesada:
    pop ax
    ret
endp


; Reproduce una nota por medio de la bocina interna
; espera en 'bx' la frecuencia de nota
proc play_nota
; Para producir sonido se prende y apaga el altavoz
; usando el 8253 timer chip en su modo 2 se envian pulsos que ejecutan tal accion generando un tono

; codigo basado en
; http://www.intel-assembler.it/portale/5/make-sound-from-the-speaker-in-assembly/8255-8255-8284-asm-program-example.asp

    push cx
    ;mov bx, 2712       ; Valor de frecuencia.
                        ; Formula = 1,193,180 \ frecuencia

    mov al, 10110110B   ; Datos para utilizar Timer 2
    out 43H, al         ; enviarlos al puerto 43H Timer 2.

    mov ax, bx          ; mover la frecuencia a AX

    out 42H, al         ; enviar LSB al puerto 42H.
    mov al, ah          ; mover MSB en AL
    out 42H, al         ; enviar MSB al puerto 42H.


    in al, 61H          ; obtener el estado del puerto 61H programmable peripheral interface
    or al, 00000011B    ; realizar operacion OR en el valor para cambiar unicamente sus dos ultimos bits en 1.
    out 61H, al         ; se copia el valor al puerto 61H del PPI Chip
                        ; para encender la bocina

    mov ah,86h          ; Duracion de la nota con interrupcion
    mov cx,7
    mov dx,0a120h
    int 15h

    in al, 61H          ; Para apagar la bocina
    and al, 11111100B   ; realizar operacion AND para cambiar unicamente sus dos ultimos bits en 0
    out 61H, al

    pop cx
    ret
endp

; proc para repetir y dibujar lineas de texto
proc dib_lineas
    push cx
    mov cx,5                 ; # lineas
    mov bh,0                 ; pagina
    mov al,0
    mov bp, offset relleno   ; caracteres a mostrar
    dib_cuadro:
        push cx
        mov cx,10            ; # caracteres
        mov ah,13h           ; muestra una cadena con atributo de color
        int 10h
        inc dh
        pop cx
        loop dib_cuadro
    pop cx
    ret
endp


; proc con las propiedades de los cuadros
proc verdeBrillante
mov bl,0aah           ; color
mov dl,29             ; col
mov dh,5              ; fila
call dib_lineas
ret
endp

proc verdeObscuro
mov bl,022h
mov dl,29
mov dh,5
call dib_lineas
ret
endp

proc rojoBrillante
mov bl,0CCh
mov dl,41
mov dh,5
call dib_lineas
ret
endp

proc rojoObscuro
mov bl,044h
mov dl,41
mov dh,5
call dib_lineas
ret
endp

proc azulBrillante
mov bl,099h
mov dl,29
mov dh,11
call dib_lineas
ret
endp

proc azulOBscuro
mov bl,011h
mov dl,29
mov dh,11
call dib_lineas
ret
endp

proc amarillo
mov bl,0EEh
mov dl,41
mov dh,11
call dib_lineas
ret
endp

proc blanco
mov bl,0ffh
mov dl,41
mov dh,11
call dib_lineas
ret
endp

msjTitulo db "Simon un juego de memoria$"
msjInstrucciones db "Presiona las teclas segun la secuencia dada$"
msjTeclas db "Teclas:$"

msjTVe db "q = Verde$"
msjTRo db "w = Rojo$"
msjTAz db "a = Azul$"
msjTAm db "s = Amarillo$"
msjTEs db "ESC = Terminar juego$"
msjTColor dw msjTVe, msjTRo, msjTAz, msjTAm, msjTEs

msjPIniciar db "Presiona ENTER para iniciar$"

msjPerdiste db "Perdiste$"
msjGanaste db "Ganaste!$"
msjSalir db "Presiona la tecla ENTER para salir$"

relleno db "12345678901234567890"
nivel1 db 'qwasqawasasaqwsawq$'
pasada dw 0
