/*****************************************************************************/
/**  Ejemplo de BISON-I: S E M - 2          2019-2020 jbenedi@dsic.upv.es> **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "libtds.h"
#include "libgci.h"
%}

%union {
int cent ;
char *ident ;
EXP exp;
listaStruct cstruct;
examenUtil examen;
}

%token STRUCT_ READ_ PRINT_ IF_ ELSE_ WHILE_ DO_ SFOR_

%token TRUE_ FALSE_    
%token MAS_ MENOS_ POR_ DIV_ MASASIG_ MENOSASIG_ PORASIG_ DIVASIG_ INCREMENTO_ DECREMENTO_ MOD_
%token OPAR_ CPAR_ OLLAVE_ CLLAVE_ OCORCHETE_ CCORCHETE_ DOSPUNTOS_ STRUCTPUNTO_
%token IGUALQUE_ NOTIGUAL_ NOT_ AND_ OR_ MENOR_ MAYOR_ MENOROIG_ MAYORIG_ 
%token ASIG_ 
%token <ident> ID_
%token <cent> INT_ BOOL_ CTE_


%type <cent> tipoSimple
%type <exp> constante
%type <cent> operadorAsignacion operadorLogico operadorIgualdad operadorRelacional
%type <cent> operadorAditivo operadorMultiplicativo operadorUnario operadorIncremento

%type <cstruct> listaCampos
%type <exp> expresion expresionLogica expresionIgualdad expresionRelacional
%type <exp> expresionAditiva expresionMultiplicativa expresionUnaria expresionSufija


%%
programa
    : {
        dvar=0;
        si=0;    
    } OLLAVE_ secuenciaSentencias CLLAVE_ { 
        if(verbosidad) {
            printf("\n\nNúmero de líneas:\t%d\n", yylineno);
        } if(verTDS){ 
            verTdS();
        }
        emite(FIN,crArgNul(),crArgNul(),crArgNul()); 
    }
    ;

secuenciaSentencias
    : sentencia
    | secuenciaSentencias sentencia
    ;

sentencia
    : declaracion
    | instruccion
    ;

declaracion
    : tipoSimple ID_ DOSPUNTOS_
	    {
            if(!insTdS($2, $1, dvar, -1)) { yyerror(ERROR_YA_DECLARADO); }
            else { dvar = dvar + TALLA_TIPO_SIMPLE; } 
        }
    | tipoSimple ID_ ASIG_ constante DOSPUNTOS_
        {
            if($1 != $4.tipo) { yyerror(ERROR_TIPOS); } 
            else {
                if(!insTdS($2, $1, dvar, -1)) { yyerror(ERROR_YA_DECLARADO); }
                else 
                { 
                        dvar = dvar + TALLA_TIPO_SIMPLE; 
                        SIMB sim = obtTdS($2);
                        emite(EASIG, crArgEnt($4.pos), crArgNul(), crArgPos(sim.desp));
                } 
            }
            
        }
    | tipoSimple ID_ OCORCHETE_ CTE_ CCORCHETE_ DOSPUNTOS_
        {
            int count = $4; 
            int ref;
            if(count <= 0) { yyerror(ERROR_ARRAY_NEG); }
            else{
                ref = insTdA($1, count);
                if(!insTdS($2, T_ARRAY, dvar, ref)){ yyerror(ERROR_YA_DECLARADO); }
                else { 
                    dvar = dvar + TALLA_TIPO_SIMPLE * count; 
                } 
            }
        }
    | STRUCT_ OLLAVE_ listaCampos CLLAVE_ ID_ DOSPUNTOS_
        {
	  int estado = insTdS($5,T_RECORD,dvar,$3.ref);
                  if(estado==0)
                  {
                      yyerror(ERROR_YA_DECLARADO);
                  }
                  else {
                      dvar+=$3.talla;
				} 

        }
    ;

tipoSimple
    : INT_ { $$=T_ENTERO;}
    | BOOL_ {$$=T_LOGICO; }
    ;

listaCampos
    : tipoSimple ID_ DOSPUNTOS_
    {
        $$.ref = insTdR(-1,$2,$1,0);
        $$.talla=TALLA_TIPO_SIMPLE;
    }
    | listaCampos tipoSimple ID_ DOSPUNTOS_
    {
        int ref = insTdR($1.ref,$3,$2,$1.talla);
        if(ref!=-1)
        {
            $$.ref=ref;
            $$.talla+=TALLA_TIPO_SIMPLE;
        }else{
            yyerror(ERROR_STRUCT_IDEXISTS);
        }
    }
    ;

instruccion
    : OLLAVE_ CLLAVE_
    | OLLAVE_ listaInstrucciones CLLAVE_
    | instruccionEntradaSaliada
    | instruccionSeleccion
    | instruccionIteracion
    | instruccionExpression
	| instruccionSfor
    ;

listaInstrucciones
    : instruccion
    | listaInstrucciones instruccion
    ;

instruccionEntradaSaliada
    : READ_ OPAR_ ID_ CPAR_ DOSPUNTOS_
    {
        SIMB idSimb=obtTdS($3);
        if(idSimb.tipo==T_ERROR)
        {
            yyerror(ERROR_INOUT_UNDECLARED);
        }else if(idSimb.tipo!=T_ENTERO)
        {
            yyerror(ERROR_INOUT_TYPE);
        }
        emite(EREAD,crArgNul(),crArgNul(),crArgPos(idSimb.desp));
    }
    | PRINT_ OPAR_ expresion CPAR_ DOSPUNTOS_
    {
        if($3.tipo!=T_ENTERO)
        {
            yyerror(ERROR_PRINT_TYPE);
        }
        emite(EWRITE,crArgNul(),crArgNul(),crArgPos($3.pos));
    }
    ;

instruccionSeleccion
    : IF_ OPAR_ expresion CPAR_
    {
        if($3.tipo == T_ERROR);
        else if($3.tipo !=T_LOGICO)
        {
            yyerror(ERROR_IF_TYPE);
        }
        $<cent>$=creaLans(si);
        emite(EIGUAL,crArgPos($3.pos),crArgEnt(0),crArgEtq(-1));
    } 
    instruccion
    {
        $<cent>$=creaLans(si);
        emite(GOTOS,crArgNul(),crArgNul(),crArgEtq(-1));
        completaLans($<cent>5,crArgEnt(si));
    } 
    ELSE_ instruccion
    {
        completaLans($<cent>7,crArgEnt(si));
    }
    ;

instruccionSfor
	: SFOR_ ID_ UNTIL_ 
	{
		SIMB simb = obtTdS($2);
		if(simb.tipo != T_ENTERO) { yyerror("El tipo de la expresion no es entero"); }
		emite(EASIG, crArgPos(idSimb.desp), crArgNul(), crArgPos($<examen>$.aux));
		$<examen>$.si=si;
	}
	expresion 
	{
		if($5.tipo == T_ERROR);
		else if($5.tipo != T_ENTERO) { yyerror("El tipo de la expresion no es entero"); }
		$<examen>$.fin=creaLans(si);
        	emite(EMAY,crArgPos($<examen>$.aux),crArgPos($5.pos),crArgEtq(-1));
	}
	instruccion
	{
		emite(ESUM, crArgPos($<examen>4.aux), crArgEnt(1), crArgPos($<examen>4.aux));
		emite(GOTOS,crArgNul(),crArgNul(),crArgEtq($<examen>4.si));
		completaLans($<cent>4.fin,crArgEtq(si));
	}
	;

instruccionIteracion
    : WHILE_
    {
        $<cent>$=si;
    } 
    OPAR_ expresion CPAR_
    {
        if($4.tipo == T_ERROR);
        else if($4.tipo!=T_LOGICO)
        {
            yyerror(ERROR_WHILE_TYPE);
        }
        $<cent>$=creaLans(si);
        emite(EIGUAL,crArgPos($4.pos),crArgEnt(0),crArgEtq(-1));
    } 
    instruccion
    {
        emite(GOTOS,crArgNul(),crArgNul(),crArgEtq($<cent>2));
        completaLans($<cent>6,crArgEtq(si));
    }
    ;

instruccionExpression
    : expresion DOSPUNTOS_
    | DOSPUNTOS_
    ;

expresion
    : expresionLogica { $$.tipo = $1.tipo; $$.pos = $1.pos; }
    | ID_ operadorAsignacion expresion { SIMB simb = obtTdS($1); 
			                            $$.tipo = T_ERROR;
			                            if(simb.tipo == T_ERROR)
				                            yyerror(ERROR_INDEFINIDO);
			                            else if(simb.tipo == T_ARRAY)
				                            yyerror(ERROR_ARRAYMD);
			                            else if(simb.tipo == T_RECORD)
				                            yyerror(ERROR_RECORDMD);
			                            else {
											if($3.tipo != T_ERROR) {
						                        if(simb.tipo != $3.tipo)
		                                            yyerror("El ID y el valor son de distinto tipo");
		                                        else {
		                                            if($2 == OP_ASIG) { $$.tipo = $3.tipo; 
                                                                        $$.pos = creaVarTemp();
                                                                        emite(EASIG, crArgPos($3.pos), crArgNul(), crArgPos($$.pos));
                                                                        emite(EASIG, crArgPos($3.pos), crArgNul(), crArgPos(simb.desp));
                                                                      }
		                                            else {
		                                                if(simb.tipo != T_ENTERO || $3.tipo != T_ENTERO)
		                                                    yyerror(ERROR_TIPOE);
		                                                else {
		                                                    if($2 == OP_MASASIG) { $$.tipo = $3.tipo; 
                                                                                   $$.pos = creaVarTemp();
                                                                                   emite(ESUM, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                   emite(ESUM, crArgPos(simb.desp), crArgPos($3.pos), crArgPos(simb.desp));
                                                                                 }
		                                                    if($2 == OP_MENOSASIG) { $$.tipo = $3.tipo; 
                                                                                     $$.pos = creaVarTemp();
                                                                                     emite(EDIF, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                     emite(EDIF, crArgPos(simb.desp), crArgPos($3.pos), crArgPos(simb.desp));
                                                                                   }
		                                                    if($2 == OP_PORASIG) { $$.tipo = $3.tipo; 
                                                                                   $$.pos = creaVarTemp();
                                                                                   emite(EMULT, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                   emite(EMULT, crArgPos(simb.desp), crArgPos($3.pos), crArgPos(simb.desp));
                                                                                 }
		                                                    if($2 == OP_DIVASIG) { $$.tipo = $3.tipo; 
                                                                                   $$.pos = creaVarTemp();
                                                                                   emite(EDIVI, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                   emite(EDIVI, crArgPos(simb.desp), crArgPos($3.pos), crArgPos(simb.desp));
                                                                                 }
		                                                }
		                                            }
		                                        } 
                                            }
				                        }       
				   }
    | ID_ OCORCHETE_ expresion CCORCHETE_ operadorAsignacion expresion{ SIMB simb = obtTdS($1);
			                                                            $$.tipo = T_ERROR;
			                                                            if(simb.tipo == T_ERROR)
				                                                            yyerror(ERROR_INDEFINIDO);
			                                                            else if(simb.tipo == T_RECORD)
				                                                            yyerror(ERROR_RECORDMD);
	                                                                    else if(simb.tipo == T_ENTERO || simb.tipo == T_LOGICO)
		                                                                    yyerror(ERROR_IDMD);
			                                                            else {
																			if($3.tipo == T_ENTERO) {
																			    if($6.tipo != T_ERROR) {
			                                                                        DIM dim = obtTdA(simb.ref);
							                                                        if(dim.telem != $6.tipo)
			                                                                            yyerror("El ID y el valor son de distinto tipo");
		                                                                            else {
		                                                                                if($5 == OP_ASIG) { $$.tipo = $6.tipo; 
																			$$.pos = creaVarTemp();
                                                                                                            emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($6.pos)); 
																											emite(EAV, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                                          }
		                                                                                else {
		                                                                                    if(dim.telem != T_ENTERO || $6.tipo != T_ENTERO)
		                                                                                        yyerror(ERROR_TIPOE);
		                                                                                    else {
                                                                                                $$.pos = creaVarTemp();
		                                                                                        if($5 == OP_MASASIG) { 
                                                                                                    $$.tipo = $6.tipo; 
																			$$.pos = creaVarTemp();
											                                                        emite(EAV, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                                    emite(ESUM, crArgPos($$.pos), crArgPos($6.pos), crArgPos($$.pos));
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos)); 
                                                                                                    }
		                                                                                        if($5 == OP_MENOSASIG) { 
                                                                                                    $$.tipo = $6.tipo; 
																			$$.pos = creaVarTemp();
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                                    emite(EDIF, crArgPos($$.pos), crArgPos($6.pos), crArgPos($$.pos));
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos)); 
                                                                                                    }
		                                                                                        if($5 == OP_PORASIG) { 
                                                                                                    $$.tipo = $6.tipo; 
																			$$.pos = creaVarTemp();
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                                    emite(EMULT, crArgPos($$.pos), crArgPos($6.pos), crArgPos($$.pos));
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos)); 
                                                                                                    }
		                                                                                        if($5 == OP_DIVASIG) { 
                                                                                                    $$.tipo = $6.tipo; 
																			$$.pos = creaVarTemp();
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
                                                                                                    emite(EDIVI, crArgPos($$.pos), crArgPos($6.pos), crArgPos($$.pos));
                                                                                                    emite(EVA, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos)); 
                                                                                                    }
		                                                                                    }
		                                                                                }
		                                                                            } 
                                                                                }
																			} else { yyerror("Acceso inadecuado al array"); } 
				                                                        }       
				                                   }
    | ID_ STRUCTPUNTO_ ID_ operadorAsignacion expresion { SIMB simb = obtTdS($1);
                                                            $$.tipo = T_ERROR;
                                                            if(simb.tipo == T_ERROR)
	                                                            yyerror(ERROR_INDEFINIDO);
                                                            else if(simb.tipo == T_ARRAY)
	                                                            yyerror(ERROR_RECORDMD);
	                                                        else if(simb.tipo == T_ENTERO || simb.tipo == T_LOGICO)
		                                                        yyerror(ERROR_IDMD);
                                                            else if (simb.tipo == T_RECORD) {
                                                                 CAMP camp = obtTdR(simb.ref,$3);
                                                                 if(camp.tipo == T_ERROR)
                                                                     yyerror(ERROR_CAMPOINDEFINIDO);
                                                                 else if(camp.tipo == T_ARRAY)
                                                                     yyerror(ERROR_ARRAYMD);
                                                                 else if(camp.tipo == T_RECORD)
	                                                                yyerror(ERROR_RECORDMD);
                                                                 else {
                                                                    if(camp.tipo != $5.tipo)
                                                                        yyerror("El ID y el valor son de distinto tipo");
                                                                    else {
                                                                        int posreal = simb.desp + camp.desp;
                                                                        if($4 == OP_ASIG) { $$.tipo = $5.tipo; 
																			$$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgPos($5.pos), crArgNul(), crArgPos(posreal)); 
                                                                            emite(EASIG, crArgPos(posreal), crArgNul(), crArgPos($$.pos)); 
                                                                        }
                                                                        else {
                                                                            if(camp.tipo != T_ENTERO || $5.tipo != T_ENTERO)
                                                                                yyerror(ERROR_TIPOE);
                                                                            else {
                                                                                if($4 == OP_MASASIG) { 
                                                                                    $$.tipo = $5.tipo; 
																			$$.pos = creaVarTemp();
                                                                                    emite(ESUM, crArgPos(posreal), crArgPos($5.pos), crArgPos(posreal));
                                                                            emite(EASIG, crArgPos(posreal), crArgNul(), crArgPos($$.pos)); 
                                                                                }
                                                                                if($4 == OP_MENOSASIG) { 
                                                                                    $$.tipo = $5.tipo;
																			$$.pos = creaVarTemp();
                                                                                    emite(EDIF, crArgPos(posreal), crArgPos($5.pos), crArgPos(posreal));
                                                                            emite(EASIG, crArgPos(posreal), crArgNul(), crArgPos($$.pos)); 
                                                                                }
                                                                                if($4 == OP_PORASIG) { 
                                                                                    $$.tipo = $5.tipo;
																			$$.pos = creaVarTemp();
                                                                                    emite(EDIVI, crArgPos(posreal), crArgPos($5.pos), crArgPos(posreal));
                                                                            emite(EASIG, crArgPos(posreal), crArgNul(), crArgPos($$.pos)); 
                                                                                }
                                                                                if($4 == OP_DIVASIG) { 
                                                                                    $$.tipo = $5.tipo;
																			$$.pos = creaVarTemp();
                                                                                    emite(EMULT, crArgPos(posreal), crArgPos($5.pos), crArgPos(posreal));
                                                                            emite(EASIG, crArgPos(posreal), crArgNul(), crArgPos($$.pos)); 
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                 }
	                                                        }       
				                                        }
    ;

expresionLogica
    : expresionIgualdad { $$.tipo = $1.tipo; $$.pos = $1.pos; }
    | expresionLogica operadorLogico expresionIgualdad { $$.tipo = T_ERROR;
                                                           if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                                                               if($2 == OP_AND) {
                                                                   if($1.tipo != T_LOGICO || $3.tipo != T_LOGICO)
                                                                       yyerror(ERROR_TIPOL);
                                                                   else
                                                                       $$.tipo = T_LOGICO;
                                                                       emite(EMULT, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                               } else if ($2 == OP_OR) {
                                                                   if($1.tipo != T_LOGICO || $3.tipo != T_LOGICO)
                                                                       yyerror(ERROR_TIPOL);
                                                                   else {
                                                                        $$.tipo = T_LOGICO;
                                                                        $$.pos = creaVarTemp();
                                                                        emite(ESUM, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                                        emite(EMENEQ, crArgPos($$.pos), crArgEnt(1), crArgEtq(si + 2));
                                                                        emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                        }

                                                               } else
                                                                   yyerror(ERROR_NOVALIDOP);
                                                           }
                                                       }
    ;

expresionIgualdad
    : expresionRelacional { $$.tipo = $1.tipo; $$.pos = $1.pos;}
    | expresionIgualdad operadorIgualdad expresionRelacional { $$.tipo = T_ERROR;
                                                               if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                                                                   if($2 == OP_IGUALQUE) {
                                                                       if($1.tipo != $3.tipo || ($1.tipo != T_ENTERO && $1.tipo != T_LOGICO))
                                                                           yyerror(ERROR_TIPO);
                                                                       else
                                                                            $$.tipo = T_LOGICO;
                                                                            $$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                            emite(EIGUAL, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+2));
                                                                            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
                                                                   } else if ($2 == OP_NOTIGUAL) {
                                                                       if($1.tipo != $3.tipo || ($1.tipo != T_ENTERO && $1.tipo != T_LOGICO))
                                                                           yyerror(ERROR_TIPO);
                                                                       else
                                                                            $$.tipo = T_LOGICO;
                                                                            $$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                            emite(EDIST, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+2));
                                                                            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
                                                                   } else
                                                                       yyerror(ERROR_NOVALIDOP);
                                                               }
                                                             }
    ;

expresionRelacional
    : expresionAditiva { $$.tipo = $1.tipo; $$.pos = $1.pos;}
    | expresionRelacional operadorRelacional expresionAditiva { $$.tipo = T_ERROR;
                                                               if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                                                                   if($2 == OP_MAYOROIG) {
                                                                       if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO){
                                                                           yyerror(ERROR_TIPOE);}
                                                                       else{
                                                                            $$.tipo = T_LOGICO;
                                                                            $$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                            emite(EMAYEQ, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+2));
                                                                            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
                                                                        }
                                                                   } else if ($2 == OP_MENOROIG) {
                                                                       if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO){
                                                                           yyerror(ERROR_TIPOE);}
                                                                       else {
                                                                            $$.tipo = T_LOGICO;
                                                                            $$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                            emite(EMENEQ, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+2));
                                                                            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
                                                                        }
                                                                   } else if ($2 == OP_MAYOR) {
                                                                       if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO){
                                                                           yyerror(ERROR_TIPOE);}
                                                                       else{
                                                                            $$.tipo = T_LOGICO;
                                                                            $$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                            emite(EMAY, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+2));
                                                                            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
                                                                        }
                                                                   } else if ($2 == OP_MENOR) {
                                                                       if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO){
                                                                           yyerror(ERROR_TIPOE);}
                                                                       else{
                                                                            $$.tipo = T_LOGICO;
                                                                            $$.pos = creaVarTemp();
                                                                            emite(EASIG, crArgEnt(1), crArgNul(), crArgPos($$.pos));
                                                                            emite(EMEN, crArgPos($1.pos), crArgPos($3.pos), crArgEtq(si+2));
                                                                            emite(EASIG, crArgEnt(0), crArgNul(), crArgPos($$.pos));
                                                                        }
                                                                   } else
                                                                       yyerror(ERROR_NOVALIDOP);
                                                               }
                                                             }
    ;
expresionAditiva
    : expresionMultiplicativa { $$.tipo = $1.tipo; $$.pos = $1.pos; }
    | expresionAditiva operadorAditivo expresionMultiplicativa { $$.tipo = T_ERROR;
                                                               if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                                                                   if($2 == OP_SUMA) {
                                                                       if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO)
                                                                           yyerror(ERROR_TIPOE);
                                                                       else
                                                                           $$.tipo = T_ENTERO;
                                                                           $$.pos = creaVarTemp();
                                                                           emite(ESUM, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                                   } else if ($2 == OP_RESTA) {
                                                                       if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO)
                                                                           yyerror(ERROR_TIPOE);
                                                                       else
                                                                           $$.tipo = T_ENTERO;
                                                                           $$.pos = creaVarTemp();
                                                                           emite(EDIF, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                                   } else
                                                                       yyerror(ERROR_NOVALIDOP);
                                                               }
                                                             }
    ;

expresionMultiplicativa
    : expresionUnaria { $$.tipo = $1.tipo; $$.pos = $1.pos; }
    | expresionMultiplicativa operadorMultiplicativo expresionUnaria { $$.tipo = T_ERROR;
                                                                       if($1.tipo != T_ERROR && $3.tipo != T_ERROR) {
                                                                           if($2 == OP_MOD) {
                                                                               if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO)
                                                                                   yyerror(ERROR_TIPOE);
                                                                               else
                                                                                   $$.tipo = T_ENTERO;
                                                                                   $$.pos = creaVarTemp();
                                                                                   emite(RESTO, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                                           } else if ($2 == OP_DIV) {
                                                                               if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO)
                                                                                   yyerror(ERROR_TIPOE);
                                                                               else
                                                                                   $$.tipo = T_ENTERO;
                                                                                   $$.pos = creaVarTemp();
                                                                                   emite(EDIVI, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                                           } else if ($2 == OP_POR) {
                                                                               if($1.tipo != T_ENTERO || $3.tipo != T_ENTERO)
                                                                                   yyerror(ERROR_TIPOE);
                                                                               else
                                                                                   $$.tipo = T_ENTERO;
                                                                                   $$.pos = creaVarTemp();
                                                                                   emite(EMULT, crArgPos($1.pos), crArgPos($3.pos), crArgPos($$.pos));
                                                                           } else
                                                                               yyerror(ERROR_NOVALIDOP);
                                                                       }
                                                                     }
    ;

expresionUnaria
    : expresionSufija { $$.tipo = $1.tipo; $$.pos = $1.pos; }
    | operadorUnario expresionUnaria { $$.tipo = T_ERROR;
                                       if($2.tipo != T_ERROR) {
                                           if($1 == OP_NOT) {
                                               if($2.tipo != T_LOGICO)
                                                   yyerror(ERROR_TIPOL);
                                               else 
                                                   $$.tipo = T_LOGICO;
                                                   $$.pos = creaVarTemp();
                                                   emite(EDIF, crArgEnt(1), crArgPos($2.pos), crArgPos($$.pos));
                                           } else if($1 == OP_MAS) {
                                                if($2.tipo != T_ENTERO)
                                                    yyerror(ERROR_TIPOE);
                                               else 
                                                   $$.tipo = T_ENTERO;
                                                   $$.pos = creaVarTemp();
                                                   emite(EASIG, crArgPos($2.pos), crArgNul(), crArgPos($$.pos));
                                           } else if($1 == OP_MENOS) {
                                                if($2.tipo != T_ENTERO)
                                                    yyerror(ERROR_TIPOE);
                                               else 
                                                   $$.tipo = T_ENTERO;
                                                   $$.pos = creaVarTemp();
                                                   emite(ESIG, crArgPos($2.pos), crArgNul(), crArgPos($$.pos));
                                           } else 
                                                yyerror(ERROR_NOVALIDOP);
                                       }
                                     }
    | operadorIncremento ID_ { SIMB simb = obtTdS($2); 
	                           $$.tipo = T_ERROR;
	                           if(simb.tipo == T_ERROR)
		                           yyerror(ERROR_INDEFINIDO);
	                           else if(simb.tipo == T_ARRAY)
		                           yyerror(ERROR_ARRAYMD);
	                           else if(simb.tipo == T_RECORD)
		                           yyerror(ERROR_RECORDMD);
	                           else if(simb.tipo == T_LOGICO)
		                           yyerror(ERROR_TIPOE);
	                           else
		                           $$.tipo = simb.tipo;
                                   $$.pos = creaVarTemp();
                                   if ($1 == OP_INC) { emite(ESUM, crArgPos(simb.desp), crArgEnt(1), crArgPos(simb.desp)); }
                                   else if ($1 == OP_DEC) { emite(EDIF, crArgPos(simb.desp), crArgEnt(1), crArgPos(simb.desp)); }
                                   emite(EASIG, crArgPos(simb.desp), crArgNul(), crArgPos($$.pos));
                            }
    ;

expresionSufija
    : OPAR_ expresion CPAR_ { $$.tipo = $2.tipo; $$.pos = $2.pos; }
    | ID_ operadorIncremento {  SIMB simb = obtTdS($1); 
	                            $$.tipo = T_ERROR;
	                            if(simb.tipo == T_ERROR)
		                            yyerror(ERROR_INDEFINIDO);
	                            else if(simb.tipo == T_ARRAY)
		                            yyerror(ERROR_ARRAYMD);
	                            else if(simb.tipo == T_RECORD)
		                            yyerror(ERROR_RECORDMD);
	                            else if(simb.tipo == T_LOGICO)
		                            yyerror(ERROR_TIPOE);
	                            else {
		                            $$.tipo = simb.tipo;
                                    $$.pos = creaVarTemp();
                                    emite(EASIG, crArgPos(simb.desp), crArgNul(), crArgPos($$.pos));
                                    if ($2 == OP_INC) { emite(ESUM, crArgPos(simb.desp), crArgEnt(1), crArgPos(simb.desp)); }
                                    else if ($2 == OP_DEC) { emite(EDIF, crArgPos(simb.desp), crArgEnt(1), crArgPos(simb.desp)); } }
                             }
    | ID_ OCORCHETE_ expresion CCORCHETE_ { SIMB simb = obtTdS($1);
                                            $$.tipo = T_ERROR;
	                                        if(simb.tipo == T_ERROR)
		                                        yyerror(ERROR_INDEFINIDO);
	                                        else if(simb.tipo == T_RECORD)
		                                        yyerror(ERROR_RECORDMD);
	                                        else if(simb.tipo == T_ENTERO || simb.tipo == T_LOGICO)
		                                        yyerror(ERROR_IDMD);
	                                        else if(simb.tipo == T_ARRAY) {
                                                if($3.tipo != T_ENTERO)
                                                    yyerror(ERROR_TIPOA);
												else {
		                                            DIM dim = obtTdA(simb.ref);
		                                            $$.tipo = dim.telem; 
                                                    $$.pos = creaVarTemp();
                                                    emite(EMULT, crArgPos($3.pos), crArgEnt(TALLA_TIPO_SIMPLE), crArgPos($3.pos));
                                                    emite(EAV, crArgPos(simb.desp), crArgPos($3.pos), crArgPos($$.pos));
												}
                                            }
                                          }
    | ID_ { SIMB simb = obtTdS($1); 
	        $$.tipo = T_ERROR;
	        if(simb.tipo == T_ERROR)
		        yyerror(ERROR_INDEFINIDO);
	        else if(simb.tipo == T_ARRAY)
		        yyerror(ERROR_ARRAYMD);
	        else if(simb.tipo == T_RECORD)
		        yyerror(ERROR_RECORDMD);
	        else
		        $$.tipo = simb.tipo;
                $$.pos = creaVarTemp();
                emite(EASIG, crArgPos(simb.desp), crArgNul(), crArgPos($$.pos));
	   }
    | ID_ STRUCTPUNTO_ ID_ { SIMB simb = obtTdS($1);
                             $$.tipo = T_ERROR;
                             if(simb.tipo == T_ERROR)
		                        yyerror(ERROR_INDEFINIDO);
                             else if(simb.tipo == T_ARRAY)
                                yyerror(ERROR_ARRAYMD);
	                         else if(simb.tipo == T_ENTERO)
		                        yyerror(ERROR_IDMD);
                             else if(simb.tipo == T_LOGICO)
		                        yyerror(ERROR_IDMD);
                             else if(simb.tipo == T_RECORD) {
                                 CAMP camp = obtTdR(simb.ref,$3);
                                 if(camp.tipo == T_ERROR)
		                            yyerror(ERROR_CAMPOINDEFINIDO);
                                 else if(camp.tipo == T_ARRAY)
                                     yyerror(ERROR_ARRAYMD);
	                             else if(camp.tipo == T_RECORD)
		                            yyerror(ERROR_RECORDMD);
                                 else
                                     $$.tipo = camp.tipo;
                                     $$.pos = creaVarTemp();
									 int posreal = simb.desp + camp.desp;
                                     emite(EASIG, crArgPos(posreal), crArgNul(), crArgPos($$.pos));
							}
                           }
    | constante { $$.tipo = $1.tipo; $$.pos = creaVarTemp(); emite(EASIG, crArgEnt($1.pos), crArgNul(), crArgPos($$.pos)); }
    ;

constante
    : CTE_ { $$.tipo = T_ENTERO; $$.pos = $1; }
    | TRUE_ { $$.tipo = T_LOGICO; $$.pos = 1; }
    | FALSE_ { $$.tipo = T_LOGICO; $$.pos = 0; }
    ;

operadorAsignacion
    : ASIG_ { $$ = OP_ASIG; }
    | MASASIG_ { $$ = OP_MASASIG; }
    | MENOSASIG_ { $$ = OP_MENOSASIG; }
    | PORASIG_ { $$ = OP_PORASIG; }
    | DIVASIG_ { $$ = OP_DIVASIG; }
    ;

operadorLogico
    : AND_ { $$ = OP_AND; }
    | OR_ { $$ = OP_OR; }
    ;

operadorIgualdad
    : IGUALQUE_ { $$ = OP_IGUALQUE; }
    | NOTIGUAL_ { $$ = OP_NOTIGUAL; }
    ;

operadorRelacional
    : MENOR_ { $$ = OP_MENOR; }
    | MAYOR_ { $$ = OP_MAYOR; }
    | MENOROIG_ { $$ = OP_MENOROIG; }
    | MAYORIG_ { $$ = OP_MAYOROIG; }
    ;

operadorAditivo
    : MAS_ { $$ = OP_SUMA; }
    | MENOS_ { $$ = OP_RESTA; }
    ;

operadorMultiplicativo
    : POR_ { $$ = OP_POR; }
    | DIV_ { $$ = OP_DIV; }
    | MOD_ { $$ = OP_MOD; }
    ;

operadorUnario
    : MAS_ { $$ = OP_MAS; }
    | MENOS_ { $$ = OP_MENOS; }
    | NOT_ { $$ = OP_NOT; }
    ;

operadorIncremento
    : INCREMENTO_ { $$ = OP_INC; }
    | DECREMENTO_ { $$ = OP_DEC; }
    ;
%%

