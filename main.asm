#------------------------------DESENVOLVIDO POR------------------------------
#                        Angelina Gomes e Felipe Amorim                      
#----------------------------------------------------------------------------

# Configuracoes do Bitmap Display para visualizacao da simulacao:
#	Unit Width/Height in pixels = 4
#	Display Width/Height in Pixels = 256
#	Base address = 0x10040000 (heap)

.data
address: 	.word   0x10040000	#endereco base do bitmap display na memoria	
ms:		.word	25		#delay movimento

corLinha:	.word	0xFBFF00	#amarelo
corRobo:	.word	0xFF0000	#vermelho


.text

inicializacao: #carrega o endereco base em um registrador
	lw $t0, address
	
semente: #seta semente para gerar numeros aleatorios
	li $v0, 30 #chamada de tempo
	syscall
	move $t0, $a0
	li $a0, 1
	move $a1, $t0
	li $v0, 40 #seta semente
	syscall

		
main:

#------------------------------DESENHA MAPA ALEATÓRIO------------------------------
	lw $t3, corLinha

	li $s7, 61 #valor maximo gerado aleatoriamente
	jal randInt #gera numero aleatorio - salva em a0
	addi $a0, $a0, 1 #aleatorio entre 1 e 62
	move $s0, $a0 #X1 aleatorio
	
	li $s7, 61
	jal randInt
	addi $a0, $a0, 1
	move $s1, $a0 #Y1 aleatorio
	
	li $s7, 1890
	jal randInt
	addi $a0, $a0, 62 #aleatorio entre 62 e 1952
	move $k0, $a0 #numero de pontos que formam a linha 
	
	li $a2, 0 #controle do loop1
	loop1:		
		bgt $a2, $k0, endLoop1
		addi $a2, $a2, 1 #incremento do controle do loop1
		
		li $s7, 1
		jal randInt
		move $t9, $a0 #eixo que o proximo ponto mantem
		
		beq $t9, 0, mKeepX #horizontal
		beq $t9, 1, mKeepY #vertical

		
		mKeepX:
			move $s2, $s0 #X2 = X1
			li $s7, 61
			jal randInt
			addi $a0, $a0, 1
			move $s3, $a0 #Y2 aleatorio
			j continua

		mKeepY:
			li $s7, 61
			jal randInt
			addi $a0, $a0, 1
			move $s2, $a0 #X2 aleatorio
			move $s3, $s1 #Y2 = Y1
			
		continua:		
		move $s4, $s0 #copia X1
		move $s5, $s1 #copia Y1
		jal verificaReta #verifica se pode desenhar a reta entre P1 e P2

		bne $t7, 0, desenha		
		beq $t7, 0, loop1
						
		desenha:  # desenha reta entre os pontos (X1,Y1) e (X2,Y2)
			jal reta #$s0:X1 $s1:Y1 $s2:X2 $s3:Y2
			move $s0, $s2 #seta X2 como novo X1
			move $s1, $s3 #seta Y2 como novo Y1
			j loop1
								
	endLoop1:
	
#------------------------------ZERA OS REGISTRADORES------------------------------
	jal clear
	li $ra, 0
	
#------------------------------------CRIA ROBO------------------------------------
	lw $t3, corRobo
	
	#define posicao aleatoria para gerar o robo
	li $s7, 61
	jal randInt
	addi $a0, $a0, 1
	move $s2, $a0 #X
	
	li $s7, 61
	jal randInt
	addi $a0, $a0, 1
	move $s3, $a0 #Y
	
	#move o robo para o ponto (1,1)
	whileX: #indo para X = 1
		beq $s2, 1, endWhileX
		
		move $t4, $s2
		move $t5, $s3
		jal obtemPonto #retorna cor do ponto em $t6
		bne $t6, 0, achou #verifica se esta na linha
		
		move $t1, $s2
		move $t2, $s3
		lw $t3, corRobo
		jal desenhaPonto #desenha o robo no ponto
		li $v0, 32
		lw $a0, ms
		syscall
		move $t1, $s2
		move $t2, $s3
		move $t3, $zero
		jal desenhaPonto #pinta o ponto de preto
		subi $s2, $s2, 1

		j whileX
	
	endWhileX: #X = 1
	move $t4, $s2
	move $t5, $s3
	jal obtemPonto
	move $t1, $s2
	move $t2, $s3
	lw $t3, corRobo
	jal desenhaPonto #desenha o robo no ponto
	bne $t6, $zero, achou #verifica se esta na linha
	
	whileY: #indo para Y = 1
		beq $s3, 1, endWhileY
		
		move $t4, $s2
		move $t5, $s3
		jal obtemPonto
		lw $t3, corLinha
		beq $t6, $t3, achou #verifica se esta na linha
	
		move $t1, $s2
		move $t2, $s3
		lw $t3, corRobo
		jal desenhaPonto #desenha o robo no ponto
		li $v0, 32
		lw $a0, ms
		syscall
		move $t1, $s2
		move $t2, $s3
		move $t3, $zero
		jal desenhaPonto #pinta o ponto de preto
		subi $s3, $s3, 1

		j whileY
	
	endWhileY: #Y = 1
	move $t4, $s2
	move $t5, $s3
	jal obtemPonto
	move $t1, $s2
	move $t2, $s3
	lw $t3, corRobo
	jal desenhaPonto #desenha o robo no ponto
	bne $t6, $zero, achou #verifica se esta na linha

	j buscaFaixa #nao achou

	achou:
		move $t1, $s2
		move $t2, $s3
		lw $t3, corRobo
		jal desenhaPonto #desenha o robo no ponto
		
		j segueFaixa
	
	buscaFaixa: #procura pela linha apartir do ponto (1,1)
		iniWhileAumentaX: #percorre de X = 1 ate X = 62
			subi $s2, $s2, 1 #X = 0
		whileAumentaX:
			addi $s2, $s2, 1 #X++
			move $t4, $s2
			move $t5, $s3
			jal obtemPonto
			lw $t3, corLinha
			beq $t6, $t3, achou #verifica se esta na linha
			move $t1, $s2
			move $t2, $s3
			lw $t3, corRobo
			jal desenhaPonto #desenha robo no ponto
			li $v0, 32
			lw $a0, ms
			syscall
			move $t1, $s2
			move $t2, $s3
			move $t3, $zero
			jal desenhaPonto #pinta o ponto de preto
				
			beq $s2, 62, endWhileAumentaX
			j whileAumentaX
				
		endWhileAumentaX:
		addi $s3, $s3, 1 #Y++
		
		addi $s2, $s2, 1 #X = 64
		whileDiminuiX: #percorre de X = 62 ate X = 1
			subi $s2, $s2, 1 #X--
			move $t4, $s2
			move $t5, $s3
			jal obtemPonto
			lw $t3, corLinha
			beq $t6, $t3, achou #verifica se esta na linha
			move $t1, $s2
			move $t2, $s3
			lw $t3, corRobo
			jal desenhaPonto #desenha robo no ponto
			li $v0, 32
			lw $a0, ms
			syscall
			move $t1, $s2
			move $t2, $s3
			move $t3, $zero
			jal desenhaPonto #pinta o ponto de preto
				
			beq $s2, 1, endWhileDiminuiX
			j whileDiminuiX
				
		endWhileDiminuiX:
		addi $s3, $s3, 1 #Y++		
			
		bge $s3, 62, endBuscaFaixa
			
		j iniWhileAumentaX
			
	endBuscaFaixa:
	
	segueFaixa: #faz o robo percorrer a linha
		li $s4, 0 #inicia frente: norte
		li $k0, 2 #indicará se começou numa ponta ou no meio da faixa
		
		sensores:
			#verificar 4 direções pra saber se está na ponta
			li $k1, 0
			#cima	
			move $t4, $s2
			move $t5, $s3
			addi $t5, $t5, 1
			jal obtemPonto
			beq $t6, 0, di
			addi $k1, $k1, 1 #se tiver linha, conta
			#direita
			di:
			move $t4, $s2
			addi $t4, $t4, 1
			move $t5, $s3
			jal obtemPonto
			beq $t6, 0, ba
			addi $k1, $k1, 1 #se tiver linha, conta
			#baixo
			ba:
			move $t4, $s2
			move $t5, $s3
			subi $t5, $t5, 1
			jal obtemPonto
			beq $t6, 0, es
			addi $k1, $k1, 1 #se tiver linha, conta
			#esquerda
			es:
			move $t4, $s2
			subi $t4, $t4, 1
			move $t5, $s3
			jal obtemPonto
			beq $t6, 0, deck
			addi $k1, $k1, 1 #se tiver linha, conta
			deck:		
			bne $k1, 1, sde
			subi $k0, $k0, 1 #esta em uma ponta da linha
			beq $k0, 0, exit #encerra o programa
			
			sde:
			move $a2, $s2 #X sensor esquerdo
			move $a3, $s3 #Y sensor esquerdo
			move $s5, $s2 #X sensor direita
			move $s6, $s3 #Y sensor direita
							
			beq $s4, 0, sensorNorte
			beq $s4, 1, sensorSul
			beq $s4, 2, sensorLeste
			beq $s4, 3, sensorOeste
			
			#define os sensores esquerda e direita para cada caso de frente
			sensorNorte:
				subi $a2, $a2, 1
				addi $s5, $s5, 1
				j verificaPasso
			sensorSul:
				addi $a2, $a2, 1
				subi $s5, $s5, 1 
				j verificaPasso
			sensorLeste:
				addi $a3, $a3, 1
				subi $s6, $s6, 1
				j verificaPasso
			sensorOeste:
				subi $a3, $a3, 1
				addi $s6, $s6, 1
				j verificaPasso
			
		verificaPasso: #verifica para onde ir
			move $t4, $a2
			move $t5, $a3
			jal obtemPonto
		
			beq $t6, 0, verDireita #nao tem linha na esquerda
			lw $t3, corLinha
			beq $t6, $t3, virarEsq #tem linha na esquerda
		
			verDireita:
				move $t4, $s5
				move $t5, $s6
				jal obtemPonto
				
				beq $t6, 0, andar #nao tem linha dos dois lados
				lw $t3, corLinha
				beq $t6, $t3, virarDir #tem linha na direita
			
			virarEsq: #define para qual direcao virar de acordo com a frente
				beq $s4, 0, virarOeste
				beq $s4, 1, virarLeste
				beq $s4, 2, virarNorte
				beq $s4, 3, virarSul
				
			virarDir: #define para qual direcao virar de acordo com a frente
				beq $s4, 0, virarLeste
				beq $s4, 1, virarOeste
				beq $s4, 2, virarSul
				beq $s4, 3, virarNorte
				
			#redefine a frente do robo
			virarNorte:
				li $s4, 0
				j andar
			virarSul:
				li $s4, 1
				j andar
			virarLeste:
				li $s4, 2
				j andar
			virarOeste:
				li $s4, 3
				j andar
			
			andar: #movimenta o robo
				move $s0, $s2 #copia X
				move $s1, $s3 #copia Y
				
				#define o incremento de X ou Y de acordo com a frente
				beq $s4, 0, incY
				beq $s4, 1, decY
				beq $s4, 2, incX
				beq $s4, 3, decX
				incX:
					addi $s2, $s2, 1
					j passo
				decX:
					subi $s2, $s2, 1
					j passo
				incY:
					addi $s3, $s3, 1
					j passo
				decY:
					subi $s3, $s3, 1
					j passo
				
				passo: #movimenta o robo para frente
					move $t4, $s2
					move $t5, $s3
					jal obtemPonto
					bne $t6, 0, nVirar #ir para frente
					move $s2, $s0 #restaura X
					move $s3, $s1 #restaura Y
					j virarDir #muda a frente para ir para outra direcao
						
					nVirar:
					move $t1, $s2
					move $t2, $s3
					lw $t3, corRobo
					jal desenhaPonto #desenha robo no ponto da frente
					move $t1, $s0
					move $t2, $s1
					lw $t3, corLinha
					jal desenhaPonto #redesenha linha onde o robo estava
					li $v0, 32 #espera alguns milissegundos
					lw $a0, ms #define os milissegundos da pausa
					syscall
					j sensores #redefine os sensores
			

#----------------------------------PROCEDIMENTOS----------------------------------

#verifica se todos os pontos entre (X1,Y1) e (X2,Y2) estao livres
verificaReta: #s4, s5, s2, s3
	      #X1, Y1, X2, Y2
	move $s6, $ra #enderecamento da chamada do procediemnto salvo em $s6
	beq $s4, $s2, verificaVertical #quando X1 = X2
	beq $s5, $s3, verificaHorizontal #quando Y1 = Y2
	
	verificaVertical:
		beq $s5, $s3, endVerificaVertical #quando Y1 = Y2
		move $t4, $s4
		move $t5, $s5
		jal obtemPonto
		bne $t6, $zero, return0 #tem linha no ponto verificado atual
		blt $s5, $s3, VsumV #quando Y1 < Y2
		bgt $s5, $s3, VsubV #quando Y1 > Y2
			
		VsumV:
			addi $s5, $s5, 1 #Y1++
			
			#verificar ao redor do ponto
			addi $a3, $s4, 1 #copia X1++
			move $t4, $a3
			move $t5, $s5
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a direita do ponto verificado atual
			
			subi $a3, $s4, 1 #copia X1--
			move $t4, $a3
			move $t5, $s5
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a esquerda do ponto verificado atual
			
			addi $a3, $s5, 1 #copia Y1++
			move $t4, $s4
			move $t5, $a3
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a frente do ponto verificado atual

			j verificaVertical
				
		VsubV:
			subi $s5, $s5, 1 #Y1--
			
			#verificar ao redor do ponto
			addi $a3, $s4, 1 #copia X1++
			move $t4, $a3
			move $t5, $s5
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a esquerda do ponto verificado atual
		
			subi $a3, $s4, 1 #copia X1--
			move $t4, $a3
			move $t5, $s5
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a direita do ponto verificado atual
			
			subi $a3, $s5, 1 #copia Y1--
			move $t4, $s4
			move $t5, $a3
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a frente do ponto verificado atual

			j verificaVertical
			
	endVerificaVertical:	
	j return1 #nao tem linha na reta vertical verificada
		
	verificaHorizontal:
		beq $s4, $s2, endVerificaHorizontal #quando X1 = X2
		move $t4, $s4
		move $t5, $s5
		jal obtemPonto
		bne $t6, $zero, return0 #tem linha no ponto verificado atual
		blt $s4, $s2, VsumH #quando X1 < X2
		bgt $s4, $s2, VsubH #quando X1 > X2
			
		VsumH:
			addi $s4, $s4, 1 #X1++
			
			#verificar ao redor do ponto
			addi $a3, $s4, 1 #copia X1++
			move $t4, $a3
			move $t5, $s5
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a frente do ponto verificado atual
											
			addi $a3, $s5, 1 #copia Y1++
			move $t4, $s4
			move $t5, $a3
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a esquerda do ponto verificado atual
					
			subi $a3, $s5, 1 #copia Y1--
			move $t4, $s4
			move $t5, $a3
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a direita do ponto verificado atual

			j verificaHorizontal
				
		VsubH:
			subi $s4, $s4, 1 #X1--
			
			#verificar ao redor do ponto
			subi $a3, $s4, 1 #copia X1--
			move $t4, $a3
			move $t5, $s5
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a frente do ponto verificado atual
			
			addi $a3, $s5, 1 #copia Y1++
			move $t4, $s4
			move $t5, $a3
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a direita do ponto verificado atual
					
			subi $a3, $s5, 1 #copia Y1--
			move $t4, $s4
			move $t5, $a3
			jal obtemPonto
			bne $t6, 0, return0 #tem linha a esquerda do ponto verificado atual

			j verificaHorizontal
						
	endVerificaHorizontal:
	j return1 #nao tem linha na reta horizontal verificada
	
	return0: #NAO PODE desenhar a reta verificada
		li $t7, 0
		jr $s6
	return1: #PODE desenhar a reta verificada
		li $t7, 1
		jr $s6


#desenha reta entre os pontos (X1,Y1) e (X2,Y2)
reta: #s0, s1, s2, s3
      #X1, Y1, X2, Y2
	move $s6, $ra #enderecamento da chamada do procediemnto salvo em $s6

	beq $s0, $s2, retaVertical #quando X1 = X2
	beq $s1, $s3, retaHorizontal #quando Y1 = Y2
	
	#altera Y1 ate que Y1 = Y2
	retaVertical:
		beq $s1, $s3, endRetaVertical #quando Y1 = Y2
		move $t1, $s0
		move $t2, $s1
		jal desenhaPonto
		blt $s1, $s3, sumV #quando Y1 < Y2
		bgt $s1, $s3, subV #quando Y1 > Y2
		sumV:
			addi $s1, $s1, 1
			j retaVertical
		subV:
			subi $s1, $s1, 1
			j retaVertical
					
	endRetaVertical:
		jr $s6
	
	#altera X1 ate que X1 = X2	
	retaHorizontal:
		beq $s0, $s2, endRetaHorizontal #quando X1 = X2
		move $t1, $s0
		move $t2, $s1
		jal desenhaPonto	
		blt $s0, $s2, sumH #quando x1 < x2
		bgt $s0, $s2, subH #quando x1 > x2
		sumH:
			addi $s0, $s0, 1
			j retaHorizontal
		subH:
			subi $s0, $s0, 1
			j retaHorizontal
			
	endRetaHorizontal:
		jr $s6


#colore o ponto definido por (X,Y)
desenhaPonto: #t1, t2, t3
	      #X,  Y,  cor
	move $a0, $t2
	li $t5, 63
	sub $a0, $t5, $a0
	mul $a0, $a0, 256 
	mul $t1, $t1, 4
	add $t0, $a0, $t1
	lw $t2, address
	add $t0, $t0, $t2
	sw $t3, 0($t0)
	
	jr $ra


#retorna o valor do ponto definido por (X,Y)
obtemPonto: #t4, t5, t6
	    #X,  Y,  valor
	li $t7, 63
	sub $t5, $t7, $t5
	add $t7, $zero, $zero
	mul $t5, $t5, 256
	mul $t4, $t4, 4
	add $t6, $t5, $t4
	lw $t8, address
	add $t6, $t6, $t8
	lw $t6, 0($t6)
	
	jr $ra


#gera um numero aleatorio
randInt:
	li $a0, 1
	addi $s7, $s7, 1
	move $a1, $s7
	li $v0, 42
	syscall
	
	jr $ra


#zera registradores utilizados
clear:
	li $a2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0
	li $s5, 0
	li $s6, 0
	li $s7, 0
	
	jr $ra


#encerra a execucao do programa
exit:
	li $v0, 10
	syscall
