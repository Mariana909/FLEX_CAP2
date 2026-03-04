/* fb2-5 -- C Language Cross-Referencer */
%option noyywrap nodefault yylineno
%x COMMENT
%x IFILE

/* Patrones nombrados reutilizables */
UCN    (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})   /* Universal Character Name */
EXP    ([Ee][-+]?[0-9]+)                         /* exponente de float */
ILEN   ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)      /* sufijo de entero */

%{
/* ----- Tabla de s?mbolos ----- */
struct symbol {
    struct ref *reflist;
    char *name;
};

struct ref {
    struct ref *next;
    char *filename;
    int flags;       /* 01 = definicion */
    int lineno;
};

#define NHASH 9997
struct symbol symtab[NHASH];

struct symbol *lookup(char*);
void addref(int, char*, char*, int);

char *curfilename;

/* ----- Stack de archivos include ----- */
struct bufstack {
    struct bufstack *prev;
    YY_BUFFER_STATE bs;
    int lineno;
    char *filename;
    FILE *f;
} *curbs;

int newfile(char *fn);
int popfile(void);

int defining;    /* 1 cuando los nombres que siguen son probablemente definiciones */
%}

%%

 /* ===== COMENTARIOS C ===== */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>([^*]|\n)+|.   /* consumir todo el contenido del comentario */
<COMMENT><<EOF>>        { printf("%s:%d: Unterminated comment\n",
                            curfilename, yylineno); return 0; }

 /* Comentario C++ (extension comun) */
"//".*\n

 /* ===== KEYWORDS DE DECLARACION -- activan 'defining' ===== */
_Bool       |
_Complex    |
_Imaginary  |
auto        |
char        |
const       |
double      |
enum        |
extern      |
float       |
inline      |
int         |
long        |
register    |
restrict    |
short       |
signed      |
static      |
struct      |
typedef     |
union       |
unsigned    |
void        |
volatile    { defining = 1; }

 /* ===== OTROS KEYWORDS -- se ignoran ===== */
break
case
continue
default
do
else
for
goto
if
return
sizeof
switch
while

 /* ===== CONSTANTES NUMERICAS ===== */
 /* Enteros: octal, decimal, hexadecimal */
0[0-7]*{ILEN}?	{ /* ignore */ }
[1-9][0-9]*{ILEN}?	{ /* ignore */ }
0[Xx][0-9a-fA-F]+{ILEN}?	{ /* ignore */ }

 /* Floats decimales */
([0-9]*\.[0-9]+|[0-9]+\.){EXP}?[flFL]?	{ /* ignore */ }
[0-9]+{EXP}[flFL]?	{ /* ignore */ }

 /* Float hexadecimal (exponente con P, no E) */
0[Xx]([0-9a-fA-F]*\.[0-9a-fA-F]+|[0-9a-fA-F]+\.?)[Pp][-+]?[0-9]+[flFL]?	{ /* ignore */ }

 /* ===== CHAR Y STRING LITERALS ===== */
'([^'\\]|\\['"?\\abfnrtv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})+'
L?"([^"\\]|\\['"?\\abfnrtv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})*"

 /* ===== PUNCTUADORES ===== */
 /* Estos tres terminan una definicion/declaracion */
"{"|"<%"|";"    { defining = 0; }

 /* El resto se ignoran */
"["|"]"|"("|")"|"{"|"}"|"."|"->"
"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"
"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"
"?"|":"|";"|"..."
"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="
","|"#"|"##"
"<:"|":>"|"%>"|"%:"|"%:%:"

 /* ===== IDENTIFICADORES ===== */
([_a-zA-Z]|{UCN})([_a-zA-Z0-9]|{UCN})*    {
    addref(yylineno, curfilename, yytext, defining);
}

 /* ===== WHITESPACE Y CONTINUACION DE LINEA ===== */
[ \t\n]+
\\$

 /* ===== DIRECTIVAS PREPROCESSOR (ignoradas excepto #include) ===== */
"#"" "*if.*\n
"#"" "*else.*\n
"#"" "*endif.*\n
"#"" "*define.*\n
"#"" "*line.*\n

 /* ===== #INCLUDE ===== */
^"#"[ \t]*include[ \t]*[\"<]    { BEGIN IFILE; }

<IFILE>[^>\"]+ {
    { int c;
      while((c = input()) && c != '\n') ;   /* consume el resto de la l?nea */
    }
    newfile(strdup(yytext));
    BEGIN INITIAL;
}

<IFILE>.|\n    {
    fprintf(stderr, "%s:%d bad include line\n", curfilename, yylineno);
    BEGIN INITIAL;
}

<<EOF>>    { if(!popfile()) yyterminate(); }

 /* ===== CARACTER INVALIDO ===== */
.    { printf("%s:%d: Mystery character '%s'\n",
           curfilename, yylineno, yytext); }

%%

/* ----- Funcion de hash ----- */
static unsigned symhash(char *sym)
{
    unsigned int hash = 0;
    unsigned c;
    while(c = *sym++) hash = hash * 9 ^ c;
    return hash;
}

/* ----- Buscar o crear entrada en la tabla ----- */
struct symbol *lookup(char *sym)
{
    struct symbol *sp = &symtab[symhash(sym) % NHASH];
    int scount = NHASH;

    while(--scount >= 0) {
        if(sp->name && !strcmp(sp->name, sym)) return sp;
        if(!sp->name) {
            sp->name = strdup(sym);
            sp->reflist = 0;
            return sp;
        }
        if(++sp >= symtab + NHASH) sp = symtab;
    }
    fputs("symbol table overflow\n", stderr);
    abort();
}

/* ----- Agregar referencia ----- */
void addref(int lineno, char *filename, char *word, int flags)
{
    struct ref *r;
    struct symbol *sp = lookup(word);

    if(sp->reflist &&
       sp->reflist->lineno == lineno &&
       sp->reflist->filename == filename) return;

    r = malloc(sizeof(struct ref));
    if(!r) { fputs("out of space\n", stderr); abort(); }

    r->next     = sp->reflist;
    r->filename = filename;
    r->lineno   = lineno;
    r->flags    = flags;
    sp->reflist = r;
}

/* ----- Comparador para qsort ----- */
static int symcompare(const void *xa, const void *xb)
{
    const struct symbol *a = xa;
    const struct symbol *b = xb;
    if(!a->name) { if(!b->name) return 0; return 1; }
    if(!b->name) return -1;
    return strcmp(a->name, b->name);
}

/* ----- Imprimir referencias (con * para definiciones) ----- */
void printrefs()
{
    struct symbol *sp;
    qsort(symtab, NHASH, sizeof(struct symbol), symcompare);

    for(sp = symtab; sp->name && sp < symtab + NHASH; sp++) {
        char *prevfn = NULL;

        struct ref *rp  = sp->reflist;
        struct ref *rpp = 0;
        struct ref *rpn;
        do {
            rpn      = rp->next;
            rp->next = rpp;
            rpp      = rp;
            rp       = rpn;
        } while(rp);

        printf("%10s", sp->name);
        for(rp = rpp; rp; rp = rp->next) {
            if(rp->filename == prevfn)
                printf(" %d", rp->lineno);
            else {
                printf(" %s:%d", rp->filename, rp->lineno);
                prevfn = rp->filename;
            }
            if(rp->flags & 01) printf("*");   /* marca definiciones con * */
        }
        printf("\n");
    }
}

/* ----- Abrir nuevo archivo (push al stack) ----- */
int newfile(char *fn)
{
    FILE *f = fopen(fn, "r");
    struct bufstack *bs = malloc(sizeof(struct bufstack));

    if(!f)  { perror(fn); return 0; }
    if(!bs) { perror("malloc"); exit(1); }

    if(curbs) curbs->lineno = yylineno;
    bs->prev     = curbs;
    bs->bs       = yy_create_buffer(f, YY_BUF_SIZE);
    bs->f        = f;
    bs->filename = fn;

    yy_switch_to_buffer(bs->bs);
    curbs       = bs;
    yylineno    = 1;
    curfilename = fn;
    return 1;
}

/* ----- Cerrar archivo actual (pop del stack) ----- */
int popfile(void)
{
    struct bufstack *bs = curbs;
    struct bufstack *prevbs;

    if(!bs) return 0;

    fclose(bs->f);
    yy_delete_buffer(bs->bs);

    prevbs = bs->prev;
    free(bs);
    if(!prevbs) return 0;

    yy_switch_to_buffer(prevbs->bs);
    curbs       = prevbs;
    yylineno    = curbs->lineno;
    curfilename = curbs->filename;
    return 1;
}

/* ----- Main ----- */
int main(argc, argv)
int argc;
char **argv;
{
    int i;

    if(argc < 2) {
        fprintf(stderr, "need filename\n");
        return 1;
    }

    for(i = 1; i < argc; i++)
        if(newfile(argv[i])) yylex();

    printrefs();
    return 0;
}
