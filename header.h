/*****************************************************************************/
/**   Ejemplo de un posible fichero de cabeceras ("header.h") donde situar  **/
/** las definiciones de constantes, variables y estructuras para MenosC.20  **/
/** Los alumos deberan adaptarlo al desarrollo de su propio compilador.     **/ 
/*****************************************************************************/
#ifndef _HEADER_H
#define _HEADER_H

/****************************************************** Constantes generales */
#define TRUE  1
#define FALSE 0

//Nuestros define
#define TALLA_TIPO_SIMPLE 1

/***************************************************** Constantes operadores */

/* Operador Asignacion */

#define OP_ASIG      0
#define OP_MASASIG   1
#define OP_MENOSASIG 2
#define OP_PORASIG   3
#define OP_DIVASIG   4

/* Operador Logico*/

#define OP_AND 0
#define OP_OR  1

/* Operador igualdad */

#define OP_IGUALQUE 0
#define OP_NOTIGUAL 1

/* Operador relacional */

#define OP_MAYOR    0
#define OP_MENOR    1
#define OP_MENOROIG 2
#define OP_MAYOROIG 3

/* Operador aditivo */

#define OP_SUMA  0
#define OP_RESTA 1

/* Operador multiplicativo */

#define OP_POR 0
#define OP_DIV  1
#define OP_MOD  2

/* Operador unario */

#define OP_MAS   0
#define OP_MENOS 1
#define OP_NOT   2

/* Operador incremento */

#define OP_INC 0
#define OP_DEC 1

/************************************************************ Mensajes error */

#define ERROR_INDEFINIDO "El ID no ha sido definido"
#define ERROR_CAMPOINDEFINIDO "El campo no ha sido definido"
#define ERROR_ARRAYMD    "Se esperaba un array y se ha recibido un elemento distinto"
#define ERROR_RECORDMD   "Se esperaba un stuct y se ha recibido un elemento distinto"
#define ERROR_IDMD   "Se esperaba un ID y se ha recibido un elemento distinto"
#define ERROR_TIPOA      "El valor pasado al array no es un entero"
#define ERROR_NOVALID    "El valor no es válido"
#define ERROR_TIPOL      "El tipo no es lógico"
#define ERROR_TIPOE      "El tipo no es entero"
#define ERROR_NOVALIDOP  "La operación no es válida"
#define ERROR_YA_DECLARADO "ID ya declarada"
#define ERROR_STRUCT_IDEXISTS "Elemento repetido en el struct"
#define ERROR_ARRAY_NEG         "Declaración inválida del array"
#define ERROR_TIPOS             "Error de tipo"
#define ERROR_INOUT_UNDECLARED  "INOUT no está declarado"
#define ERROR_INOUT_TYPE "Error en el tipo de INOUT"
#define ERROR_PRINT_TYPE "Error en el tipo de PRINT"
#define ERROR_IF_TYPE "Error en el tipo de IF"
#define ERROR_WHILE_TYPE "Error en el tipo de WHILE"
#define ERROR_TIPO "Error de tipo"

/************************************* Variables externas definidas en el AL */
extern int yylex();
extern int yyparse();

extern FILE *yyin;                           /* Fichero de entrada           */
extern int   yylineno;                       /* Contador del numero de linea */
extern char *yytext;                         /* Patron detectado             */
/********* Funciones y variables externas definidas en el Programa Principal */
extern void yyerror(const char * msg) ;   /* Tratamiento de errores          */

extern int verbosidad;                   /* Flag si se desea una traza       */
extern int numErrores;              /* Contador del numero de errores        */

extern int verTDS;      //Con -t se motrara la tabla TDS al finalizar la ejecución
extern int dvar;        //Desplazamiento en el segmento de variables

//Variables externas defindas en las librerias
extern int si; //Desplazamiento relativo en el Segmento de Codigo

//Estructuras creadas por nosotros

typedef struct
{
    int ref;
    int talla;
}listaStruct;

typedef struct
{
    int tipo;
    int pos;
}EXP;

typedef struct {
    int fin;
    int si;
    int aux;
    } examenUtils;

#endif  /* _HEADER_H */
/*****************************************************************************/
