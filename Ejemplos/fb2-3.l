/* fb2-3 — Skeleton for nested include files */
%option noyywrap
%x IFILE

%{
struct bufstack {
    struct bufstack *prev;   /* entrada anterior en el stack */
    YY_BUFFER_STATE bs;      /* buffer guardado */
    int lineno;              /* número de línea guardado */
    char *filename;          /* nombre del archivo */
    FILE *f;                 /* puntero al archivo */
} *curbs = 0;

char *curfilename;           /* nombre del archivo actual */

int newfile(char *fn);
int popfile(void);
%}

%%


^"#"[ \t]*include[ \t]*[\"\<]    { 
                /* Detecta "#include" hasta la comilla o < que precede al nombre */
                                    BEGIN IFILE; }


<IFILE>[^ \t\n\">\]+    { /* En estado IFILE: lee el nombre del archivo */
    { int c;
      while((c = input()) && c != '\n') ;   /* consume el resto de la línea */
    }
    yylineno++;
    if(!newfile(yytext))
        yyterminate();    /* no existe el archivo */
    BEGIN INITIAL;
}


<IFILE>.|\n    { /* Input inválido dentro de IFILE */
    fprintf(stderr, "%4d bad include line\n", yylineno);
    yyterminate();
}


<<EOF>>    { /* Al llegar al EOF de cualquier archivo: hacer pop del stack */
            if(!popfile()) yyterminate(); }


^.     { fprintf(yyout, "%4d %s", yylineno, yytext); }
^\n    { fprintf(yyout, "%4d %s", yylineno++, yytext); }
\n     { ECHO; yylineno++; }
.      { ECHO; }

%%

main(int argc, char **argv)
{
    if(argc < 2) {
        fprintf(stderr, "need filename\n");
        return 1;
    }
    if(newfile(argv[1]))
        yylex();
}


int newfile(char *fn)
{
    /* Abre un nuevo archivo y lo empuja al stack de buffers */

    FILE *f = fopen(fn, "r");
    struct bufstack *bs = malloc(sizeof(struct bufstack));

    if(!f)  { perror(fn); return 0; }
    if(!bs) { perror("malloc"); exit(1); }

    /* Guarda el lineno del archivo actual antes de cambiarlo */
    if(curbs) curbs->lineno = yylineno;

    bs->prev = curbs;
    bs->bs   = yy_create_buffer(f, YY_BUF_SIZE);  /* crea buffer flex */
    bs->f    = f;
    bs->filename = fn;

    yy_switch_to_buffer(bs->bs);  /* activa el nuevo buffer */
    curbs = bs;
    yylineno = 1;
    curfilename = fn;
    return 1;
}


int popfile(void)
{
    /* Cierra el archivo actual y restaura el anterior */
    struct bufstack *bs = curbs;
    struct bufstack *prevbs;

    if(!bs) return 0;

    fclose(bs->f);
    yy_delete_buffer(bs->bs);   /* libera el buffer flex */

    prevbs = bs->prev;
    free(bs);

    if(!prevbs) return 0;       /* era el último archivo */

    yy_switch_to_buffer(prevbs->bs);  /* restaura buffer anterior */
    curbs = prevbs;
    yylineno = curbs->lineno;
    curfilename = curbs->filename;
    return 1;
}
