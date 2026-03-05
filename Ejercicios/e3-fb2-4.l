/* fb2-4 — Text concordance generator */
%option noyywrap nodefault yylineno case-insensitive

%{
#include <ctype.h>
#include <string.h>

/* ----- Estructuras de datos ----- */
struct symbol {
    char *name;           /* la palabra */
    struct ref *reflist;  /* lista de referencias */
};

struct ref {
    struct ref *next;
    char *filename;
    int flags;
    int lineno;
};

#define NHASH 9997
struct symbol *symtab;
int nhash = NHASH;

struct symbol *lookup(char*);
void addref(int, char*, char*, int);

char *curfilename;               /* nombre del archivo que se está leyendo */
%}

%%

/* Palabras comunes en español: se ignoran (acción = | significa "misma acción que la siguiente") */
el      |
la      |
los     |
las     |
un      |
una     |
unos    |
unas    |
a       |
de      |
en      |
con     |
por     |
para    |
sin     |
sobre   |
entre   |
hasta   |
desde   |
hacia   |
y       |
o       |
u       |
e       |
ni      |
que     |
si      |
pero    |
mas     |
aunque  |
como    |
cuando  |
yo      |
tu      |
se      |
nos     |
les     |
lo      |
le      |
me      |
te      /* ignore — no hace nada */

/* Palabra normal (incluye 's y 't al final, ej: owner's, can't) */
[a-z]+(\`(s|t))?    { addref(yylineno, curfilename, yytext, 0); }

/* Ignorar cualquier otro carácter */
.|\n

%%

/* ----- Función de hash ----- */
static unsigned symhash(char *sym)
{
    unsigned int hash = 0;
    unsigned c;
    while(c = tolower(*sym++)) hash = hash * 9 ^ c;
    return hash;
}

/* ----- Buscar o crear una entrada en la tabla ----- */
struct symbol *lookup(char *sym)
{
    struct symbol *sp = &symtab[symhash(sym) % NHASH];
    int scount = NHASH;

    while(--scount >= 0) {
        if(sp->name && !strcasecmp(sp->name, sym)) return sp;  /* encontrado */
        if(!sp->name) {                                      /* entrada libre */
            sp->name = strdup(sym);
            sp->reflist = 0;
            return sp;
        }
        if(++sp >= symtab + NHASH) sp = symtab;  /* wrap around */
    }
    fputs("symbol table overflow\n", stderr);
    abort();
}

/* ----- Agregar una referencia a un símbolo ----- */
void addref(int lineno, char *filename, char *word, int flags)
{
    struct ref *r;
    struct symbol *sp = lookup(word);

    /* evitar duplicados de la misma línea y archivo */
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

/* ----- Imprimir la concordancia ordenada ----- */
void printrefs()
{
    struct symbol *sp;
    qsort(symtab, NHASH, sizeof(struct symbol), symcompare);

    for(sp = symtab; sp->name && sp < symtab + NHASH; sp++) {
        char *prevfn = NULL;

        /* invertir la lista (fue construida al revés) */
        struct ref *rp  = sp->reflist;
        struct ref *rpp = 0;
        struct ref *rpn;
        do {
            rpn      = rp->next;
            rp->next = rpp;
            rpp      = rp;
            rp       = rpn;
        } while(rp);

        /* imprimir palabra y referencias */
        printf("%10s", sp->name);
        for(rp = rpp; rp; rp = rp->next) {
            if(rp->filename == prevfn)
                printf(" %d", rp->lineno);
            else {
                printf(" %s:%d", rp->filename, rp->lineno);
                prevfn = rp->filename;
            }
        }
        printf("\n");
    }
}

/* ----- Main ----- */
main(argc, argv)
int argc;
char **argv;
{
    int i;

    if(argc < 2) {
        curfilename = "(stdin)";
        yylineno = 1;
        symtab = malloc(nhash * sizeof(struct symbol));
        if(!symtab) { fputs("out of space\n", stderr); abort(); }
        yylex();
    } else {
        for(i = 1; i < argc; i++) {
            FILE *f = fopen(argv[i], "r");
            if(!f) { perror(argv[1]); return (1); }
            curfilename = argv[i];
            yyrestart(f);
            yylineno = 1;
            symtab = malloc(nhash * sizeof(struct symbol));
            if(!symtab) { fputs("out of space\n", stderr); abort(); }
            yylex();
            fclose(f);
        }
    }
    printrefs();
}
