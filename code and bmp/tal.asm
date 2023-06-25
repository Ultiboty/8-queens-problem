IDEAL 
MODEL small
STACK 100h

DATASEG


;-------------------------------------------------------
;image vars
;-------------------------------------------------------

stor        dw      0      ;our memory location storage
imgHeight dw 50  ;Height of image that fits screen
imgWidth dw 120   ;Width of image that fits screen
adjustCX dw ?     ;Adjusts register CX
filename db 20 dup (?) ;Generates the file's name 
filehandle dw ?  ;Handles the file
Header db 54 dup (0)  ;Read BMP file header, 54 bytes
Palette db 256*4 dup (0)  ;Enable colors
ScrLine db 320 dup (0)   ;Screen Line
Errormsg db 'Error', 13, 10, '$'   ;In case of not having all the files, Error message pops
printAdd dw ?   ;Enable to add new graphics
NumberR dw ?; random number
;------------------------------------------------------
;code vars
;-----------------------------------------------------


board db 'board.bmp', 0   ;board image var
bqueen db 'bqueen.bmp', 0 ;brown queen image var
wqueen db 'wqueen.bmp', 0 ;white queen image var
wsqure db 'wsqure.bmp', 0
bsqure db 'bsqure.bmp', 0
solveButton db 'solve.bmp', 0
tryButton db 'try.bmp', 0
resetButton db 'reset.bmp', 0
goodjob db 'goodjob.bmp', 0
pixelCounter db 0
WorBcounter db 0; white or black counter
two db 2
twentyfive db 25
arrayLocation dw 0
queens db 64 dup(0);array of all of the squers of the baord,0 is no queen in squre and 1 is qween in squre
row db 0
col db 0
arrayNum db ?
isSafe db ?
counter dw ?
mouseButtonCheck db ?
CODESEG
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;until now, image code from Hila
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------



;Prints the bmp file provided
;IN: ax - img offset, imgHeight (dw), imgWidth (dw), printAdd (dw)
;OUT: printed bmp file
proc PrintBmp
    push cx
    push di
    push si
    push cx
    push ax
    xor di, di
    mov di, ax
    mov si, offset filename
    mov cx, 20
Copy:
    mov al, [di]
    mov [si], al
    inc di
    inc si
    loop Copy
    pop ax
    pop cx
    pop si
    pop di
    call OpenFile
    call ReadHeader
    call ReadPalette
    call CopyPal
    call CopyBitMap
    call CloseFile
    
    pop cx
    ret
endp PrintBmp

proc GraphicsMode
    push ax
    
    mov ax, 13h
    int 10h
        
    pop ax
    ret
endp GraphicsMode

;in proc PrintBmp
proc OpenFile
    mov ah,3Dh
    xor al,al ;for reading only
    mov dx, offset filename
    int 21h
    jc OpenError
    mov [filehandle],ax
    ret
OpenError:
    mov dx,offset Errormsg
    mov ah,9h
    int 21h
    ret
endp OpenFile

;in proc PrintBmp
proc ReadHeader
;Read BMP file header, 54 bytes
    mov ah,3Fh
    mov bx,[filehandle]
    mov cx,54
    mov dx,offset Header
    int 21h
    ret
endp ReadHeader

;in proc PrintBmp
proc ReadPalette
;Read BMP file color palette, 256 colors*4bytes for each (400h)
    mov ah,3Fh
    mov cx,400h
    mov dx,offset Palette
    int 21h
    ret
endp ReadPalette

;in proc PrintBmp
proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
    mov si,offset Palette
    mov cx,256
    mov dx,3C8h ;port of Graphics Card
    mov al,0 ;number of first color
    ;Copy starting color to port 3C8h
    out dx,al
    ;Copy palette itself to port 3C9h
    inc dx
PalLoop:
    ;Note: Colors in a BMP file are saved as BGR values rather than RGB.    
    mov al,[si+2] ;get red value
    shr al,1    ; Max. is 255, but video palette maximal value is 63. Therefore dividing by 4
    shr al,1
    out dx,al ;send it to port
    mov al,[si +1];get green value
    shr al,1
    shr al,1
    out dx,al   ;send it
    mov al,[si]
    shr al,1
    shr al,1
    out dx,al   ;send it
    add si,4    ;Point to next color (There is a null chr. after every color)
    loop PalLoop
    ret
endp CopyPal

;in proc PrintBmp
proc CopyBitMap
; BMP graphics are saved upside-down.
; Read the graphic line by line ([height] lines in VGA format),
; displaying the lines from bottom to top.
    mov ax,0A000h ;value of start of video memory
    mov es,ax   
    push ax
    push bx
    mov ax, [imgWidth]
    mov bx, 4
    div bl
    
    cmp ah, 0
    jne NotZero
Zero:
    mov [adjustCX], 0
    jmp Continue
NotZero:
    mov [adjustCX], 4
    xor bx, bx
    mov bl, ah
    sub [adjustCX], bx
Continue:
    pop bx
    pop ax
    mov cx, [imgHeight] ;reading the BMP data - upside down
    
PrintBMPLoop:
    push cx
    xor di, di
    push cx
    dec cx
    Multi:
        add di, 320
        loop Multi
    pop cx

    add di, [printAdd]
    mov ah, 3fh
    mov cx, [imgWidth]
    add cx, [adjustCX]
    mov dx, offset ScrLine
    int 21h
    ;Copy one line into video memory
    cld ;clear direction flag - due to the use of rep
    mov cx, [imgWidth]
    mov si, offset ScrLine
    rep movsb   ;do cx times:
                ;mov es:di,ds:si -- Copy single value form ScrLine to video memory
                ;inc si --inc - because of cld
                ;inc di --inc - because of cld
    pop cx
    loop PrintBMPLoop
    ret
endp CopyBitMap

;in proc PrintBmp
proc CloseFile
    mov ah,3Eh
    mov bx,[filehandle]
    int 21h
    ret
endp CloseFile


;enables graphics mode
;IN: X
;OUT: graphics mode enabled



;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;until now, image code from Hila
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------

proc WaitForMouse
    ;Initializes the mouse
    mov ax,0h
    int 33h
    ;Show mouse
    mov ax,1h
    int 33h
    MouseLP :
    mov ax,3h
    int 33h
    cmp bx, 01h ; check left mouse click
    jne MouseLP
    shr cx,1 ; adjust cx to range 0-319, to fit screen
    
    ;check if cords are in buttons
    cmp cx, 200;x
    jl notButton; if lower, user clicked on board
    cmp dx, 50;y
    jl solveB
    cmp dx, 100
    jl try
    cmp dx, 150
    jl Reset
    jmp MouseLP
    
notButton:
    jmp MouseLP
    
solveB:
    call ClearBoard
    call Solve
    call PrintQueens
    jmp MouseLP
    
Reset:
    mov [counter], 0
    call ClearBoard
    call PrintQueens
    jmp MouseLP

PrintWin:
    mov ax, offset goodjob
    mov [printAdd], 0
    mov [imgHeight], 200
    mov [imgWidth], 200
    call PrintBmp
    jmp MouseLP
try:
    cmp [counter], 8
    je PrintWin
    mov ax,3h
    int 33h
    cmp bx, 01h ; check left mouse click
    jne try
    shr cx,1 ; adjust cx to range 0-319, to fit screen
    ;check if cords are in reset button
    cmp cx, 200;x
    jl boardClick; if lower, user clicked on board
    cmp dx, 100
    jl try
    cmp dx, 150
    jl Reset
    jmp try
boardClick:
    mov bl, 25
    mov ax, cx; move x to ax
    div bl
    mov [col], al
    mov ax, dx; move y to ax
    div bl; al have the answer
    mov [row], al
    call IsSqrSafeTry
    cmp [isSafe], 0
    je place
    jmp try
place:
    inc [counter]
    mov al, [row]
    mov ah, 8
    mul ah
    add ax, [word ptr col]
    mov bx, offset queens 
    add bx, ax
    mov [bx], 1
    ;mov ah, 2h
    ;int 33h
    call PrintQueens
    ;mov ax,1h
    ;int 33h
    jmp try
    ret
endp WaitForMouse



    
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;clear board, reset array to 0
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------    




proc ClearBoard;reset all of the queens array to 0
    mov cx, 64
    mov bx, offset queens
Clear:
    mov [bx], 0 
    inc bx
    loop Clear
    ret
endp ClearBoard



;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;print board and queens based on array
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------




proc PrintQueens
    mov [imgHeight], 25
    mov [imgWidth], 25
    mov cx, 64
    mov [pixelCounter], 0
    mov [WorBcounter], 0
    mov [printAdd], 0
    mov bx, offset queens
checkLoop:
    mov al, [WorBcounter]
    mov ah, 0
    div [two];devide al(white or black counter) by 2
    push bx
    push cx
    cmp [byte ptr bx], 0;compare
    jne printQ;if 0,print squre   
printSqr:
    cmp ah, 0;if zugi, print brown squre
    je printBsqure
    jmp printWsqure; else print white squre
printBsqure:
    mov ax, offset bsqure
    call PrintBmp
    jmp endloop
    
printWsqure:
    mov ax, offset wsqure
    call PrintBmp
    jmp endloop    
printQ:
    cmp ah, 0;if zugi, print brown queen
    je printBqueen
    jmp printWqueen
printBqueen:
    mov ax, offset bqueen
    call PrintBmp
    jmp endloop
printWqueen:
    mov ax, offset wqueen
    call PrintBmp
    jmp endloop    
endloop:
    pop cx
    pop bx
    add [pixelCounter], 25; move in imagination to next squre
    cmp [pixelCounter], 200; check if next squre is outside board
    je lineDown
    jmp endPart2    
lineDown:
    add [printAdd], 7800;+8000 line down, -200 return to start of line
    mov [pixelCounter], 0;reset check line
    inc [WorBcounter];without this it will be rows instead of squres
    jmp endPart2 
endPart2:
    add [printAdd], 25; move to next squre
    inc [WorBcounter]
    inc bx
    loop checkLoop
    ret
    
endp PrintQueens




;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;recursion that solves the problem
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------



proc Solve
    call ClearBoard
    mov bx, offset queens
    mov [col], 0
rand:
    call RandomNumber
    mov ax, [NumberR]
    mov [row], al
    jmp rowLoop
placeQueen:
    mov [row], 0;reset row to 0 in every run of the recursion
    cmp [col], 8;check if we managed to place 8 queens
    je endOfSolve
    cmp [col], 1
    jl rand
rowLoop:
    cmp [row], 8
    je didntSucced;if we didnt find a safe sqr in any row, we need to go 1 col back
    
    call IsSqrSafe
    cmp [isSafe], 0
    je sqrSafe
    inc [row]
    jmp rowLoop;if not safe, go to next row and check again
sqrSafe:
    mov al, [row]
    mov ah, 8
    xor dx, dx
    mul ah
    add ax, [word ptr col]; location of the checked squre in arra
    mov bx, offset queens
    add bx, ax
    mov [bx], 1;place queen
    inc [col]; move to next col
    push [word ptr row];save row incase its not the right solution
    jmp placeQueen; this is the recursion that solves the solution
    
didntSucced:
    sub [col], 1;go back the previous col  
    pop ax
    mov [row], al
    mov ah, 8
    xor dx, dx
    mul ah
    add ax, [word ptr col]; location of the checked squre in arra
    mov bx, offset queens
    add bx, ax
    mov [bx], 0;remove queen
    inc [row] 
    jmp rowLoop;check the next rows
endOfSolve:
    pop ax;we pop the 8 rows we pushed so we can exit proc
    pop ax
    pop ax
    pop ax
    pop ax
    pop ax
    pop ax
    pop ax
    ret
endp Solve

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;Protocol that checks if u can place a queen at a certain spot in the array, returns answer in var isSafe
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
proc IsSqrSafe
    mov [isSafe], 0
    mov cx, [word ptr col]
checkRow:
    mov al, [row]
    mov ah, 8
    xor dx, dx
    mul ah
    add ax, cx
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe
    cmp cx, 0;so the loop wont be infinite
    je checkCX
    sub cx, 1
    jmp checkRow
checkCX:    
    mov cx, [word ptr row];for next check
    mov dx, [word ptr col];for next check
checkUpperDig:
    mov al, cl
    mov ah, 8
    push dx
    xor dx, dx
    mul ah
    pop dx
    add ax, dx; location of the checked squre in array
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe
    
    ;checks to end loop
    cmp dx, 0
    je checkLowerDig
    sub dx, 1
    cmp cx, 0
    je checkLowerDig
    sub cx, 1
    jmp checkUpperDig;iv'e done the loop menually cus i need the loop to run on cx=0
    
    
checkLowerDig:
    mov cx, [word ptr col]
    mov dx, [word ptr row]
theLoop:
    mov al, dl
    mov ah, 8
    push dx
    xor dx, dx
    mul ah
    pop dx
    add ax, cx; location of the checked squre in array
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe
    
    ;checks to end loop
    cmp cx, 0
    je ending
    sub cx, 1
    cmp dx, 7
    je ending
    inc dx
    jmp theLoop;iv'e done the loop menually cus i need the loop to run on cx=0
    
    
notSafe:
    mov [isSafe], 1
    jmp ending
    
ending:
    ret
endp IsSqrSafe



proc IsSqrSafeTry
    mov [isSafe], 0
    mov cx, 1
checkRow1:
    mov al, [row]
    inc al
    mov ah, 8
    mul ah
    sub ax, cx
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe1
    cmp cx, 8;so the loop wont be infinite
    je checkColVars1
    inc cx
    jmp checkRow1
    
checkColVars1:
    mov cl, 7
    mov dx, [word ptr col]
checkCol1:
    mov al, cl
    mov ah, 8
    mul ah
    add ax, dx
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe1
    cmp cl, 0
    je checkUpperVars1
    dec cl
    jmp checkCol1
    
checkUpperVars1:    
    mov cx, [word ptr row];for next check
    mov dx, [word ptr col];for next check   
checkUpperDig1:
    mov al, cl
    mov ah, 8
    mul ah
    add ax, dx; location of the checked squre in array
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe1
    
    ;checks to end loop
    cmp dx, 0
    je checkUpperVars2
    dec dx
    cmp cx, 0
    je checkUpperVars2
    dec cx
    jmp checkUpperDig1;iv'e done the loop menually cus i need the loop to run on cx=0
 
checkUpperVars2:    
    mov cx, [word ptr row];for next check
    mov dx, [word ptr col];for next check   
checkUpperDig2:
    mov al, cl
    mov ah, 8
    mul ah
    add ax, dx; location of the checked squre in array
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe1
    
    ;checks to end loop
    cmp dx, 7
    je checkLowerDig1
    inc dx
    cmp cx, 7
    je checkLowerDig1
    inc cx
    jmp checkUpperDig2;iv'e done the loop menually cus i need the loop to run on cx=0 
    
    
notSafe1:
    mov [isSafe], 1
    jmp ending1   
    
checkLowerDig1:
    mov cx, [word ptr col]
    mov dx, [word ptr row]
theLoop1:
    mov al, dl
    mov ah, 8
    push dx
    xor dx, dx
    mul ah
    pop dx
    add ax, cx; location of the checked squre in array
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe1
    
    ;checks to end loop
    cmp cx, 0
    je checkLowerDig2
    sub cx, 1
    cmp dx, 7
    je checkLowerDig2
    inc dx
    jmp theLoop1;iv'e done the loop menually cus i need the loop to run on cx=0
    
checkLowerDig2:
    mov cx, [word ptr col]
    mov dx, [word ptr row]
theLoop2:
    mov al, dl
    mov ah, 8
    push dx
    xor dx, dx
    mul ah
    pop dx
    add ax, cx; location of the checked squre in array
    mov bx, offset queens
    add bx, ax
    cmp [bx], 1
    je notSafe1
    
    ;checks to end loop
    cmp cx, 7
    je ending1
    inc cx
    cmp dx, 0
    je ending1
    dec dx
    jmp theLoop2;iv'e done the loop menually cus i need the loop to run on cx=0

    
ending1:
    ret
endp IsSqrSafeTry

;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;Protocol that checks if u can place a queen at a certain spot in the array, returns answer in var isSafe
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
PROC RandomNumber
    mov BX, [NumberR]; maybe mov to bx [NumberR], need to check
    mov AX, 40h
    mov es, AX
Random:
    mov AX, [es:06ch]
    xor al, [byte cs:bx]
    and al, 00001111b
    mov dl, al
    ADD bx, AX
    CMP dl, 7
    JG Random
    CMP dl, 0
    JE Random
    mov [byte ptr NumberR], dl
    RET
ENDP RandomNumber



;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;Protocol that checks if u can place a queen at a certain spot in the array, returns answer in var isSafe
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------

proc PrintMainScreen
    mov [printAdd], 0
    mov [imgHeight], 25;change size to queen image
    mov [imgWidth], 25
    call ClearBoard
    call PrintQueens
    mov [printAdd], 200
    mov [imgHeight], 50;change button to queen image
    mov [imgWidth], 120 
    mov ax, offset solveButton
    call PrintBmp;print solveButton
    add [printAdd], 16000;go down to next button
    mov ax, offset tryButton
    call PrintBmp;print tryButton
    add [printAdd], 16000;go down to next button
    mov ax, offset resetButton
    call PrintBmp;print resetButton
    ret
endp PrintMainScreen



start:
    mov ax, @data
    mov ds, ax
       
    call GraphicsMode
    
    call PrintMainScreen
    call WaitForMouse
    
       
    mov ah, 1
    int 21h
exit:
    mov ax, 4c00h
    int 21h
END start