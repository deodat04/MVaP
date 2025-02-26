grammar Calcul;

@header {
import java.util.HashMap;
}


@parser::members {

    private TablesSymboles tablesSymboles = new TablesSymboles();

    private int _cur_label = 1;
    /** générateur de nom d'étiquettes pour les boucles */
    private String newLabel( ) { return "Label"+(_cur_label++); }; 


    private String evalexpr (String x, String op, String y) {
        if ( op.equals("*") ){
            return x + y + "MUL\n";
        } else if ( op.equals("+") ){
            return x + y + "ADD\n";
        } else if ( op.equals("-") ){
            return x + y + "SUB\n";
        }  else if ( op.equals("/") ){
            return x + y + "DIV\n";
        } else if ( op.equals("%") ){
            return x + y + "MOD\n";
        } else {
           System.err.println("Opérateur arithmétique incorrect : '"+op+"'");
           throw new IllegalArgumentException("Opérateur arithmétique incorrect : '"+op+"'");
        }
    }

   

}


start : calcul EOF;


calcul returns [ String code ]
@init{ $code = new String(); }   // On initialise une variable pour accumuler le code 
@after{ System.out.println($code); } // On affiche le code effectivement produit

    :   ( decl  { $code += $decl.code; })*
        NEWLINE*

        (instruction { $code += $instruction.code; })*

        { $code += "  HALT\n"; }

        EOF
    ;


instruction returns [ String code ] 
    : expression finInstruction 
        { 
            $code = $expression.code;
        }
    |  assignation finInstruction
        {
           $code = $assignation.code; 
        }
    | input finInstruction
        { $code = $input.code; }

    | output finInstruction
        { $code = $output.code; }

    | bloc
        { $code = $bloc.code; }

    | logique
        { $code = $logique.code; }

    | operateur
        { $code = $operateur.code; }

    | condition
        { $code = $condition.code; }


    | 'while' '(' condition ')' a = instruction
        {
            String boucle1 = newLabel();
            String boucle2 = newLabel();
            
            $code = "LABEL " + boucle1 + "\n";
            $code += $condition.code;
            $code += "JUMPF "+ boucle2 + "\n";
            $code += $a.code;
            $code += "JUMP "+ boucle1 + "\n";
            $code += "LABEL "+ boucle2 + "\n";
        }

    | finInstruction
    ; 

expression returns [ String code ]
    :   '-' expression {$code = "PUSHI 0\n" + $expression.code + "SUB\n";}
    |   g=expression op=('*'|'/'|'%') d=expression {$code = evalexpr($g.code, $op.text, $d.code);}
    |   g=expression op=('+'|'-') d=expression  {$code = evalexpr($g.code, $op.text, $d.code);}
    | '(' a=expression ')' { $code = $a.code;}
    |   ENTIER  {$code = "PUSHI " + $ENTIER.text+"\n";}
    |   IDENTIFIANT  
        {
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code =  "PUSHG " + vi.address + "\n";
        }
    ;

finInstruction : ( NEWLINE | ';' )+ ;

decl returns [ String code ]
    :  TYPE IDENTIFIANT '=' expression finInstruction
        {  
            tablesSymboles.addVarDecl($IDENTIFIANT.text, $TYPE.text);
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = "PUSHI 0\n" + $expression.code + "STOREG " + vi.address + "\n";
        }
    |   TYPE IDENTIFIANT finInstruction
        {
           tablesSymboles.addVarDecl($IDENTIFIANT.text,"int");
           VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
           $code = "PUSHI 0\n";
            
        }
    ;


assignation returns [ String code ] 
    : IDENTIFIANT '=' expression
        {  
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code =  $expression.code + "STOREG " + vi.address + "\n";
        }

    |   IDENTIFIANT '+=' expression
        {  
            VariableInfo vim = tablesSymboles.getVar($IDENTIFIANT.text);
             $code = "PUSHG " + vim.address + "\n" 
                  + $expression.code
                  + "ADD\n"                
                  + "STOREG " + vim.address + "\n";
        }
    ;



input returns [ String code ]
    : 'input' '(' IDENTIFIANT ')' 
        {  
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = "READ\nSTOREG " + vi.address + "\n";
        }
    ;


output returns [ String code ]
    : 'output' '(' IDENTIFIANT ')' 
        {  
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = "PUSHG " + vi.address + "\nWRITE\n";
        }

    | 'output' '(' expression ')' 
        {  
            $code = $expression.code;
            $code = "WRITE\n";
        }
    ;

bloc returns[ String code ]
@init{ $code = new String(); }
    : '{' NEWLINE? (instruction { $code += $instruction.code; })* '}' NEWLINE*
    ;

condition returns [String code]
    : 'True'  { $code = "PUSHI 1\n"; }
    | 'False' { $code = "PUSHI 0\n"; }
    ;

operateur returns [String code]
    : '>'  { $code = "SUP\n"; }
    | '>=' { $code = "SUPEQ\n"; }
    | '<' { $code = "INF\n"; }
    | '<=' { $code = "INFEQ\n"; }
    | '==' { $code = "EQUAL\n"; }
    | '!=' { $code = "NEQ\n"; }
    ;


logique returns [String code]
    : 'not' logique { $code = $logique.code + "PUSHI 0\nEQUAL\n"; }
    | a=logique 'and' b=logique  { $code = $a.code + $b.code + "MUL\n"; }
    | a=logique 'or' b=logique  { $code = $a.code + $b.code + "PUSHI 0\nSUP\n"; }
    | '(' logique ')'{ $code = $logique.code; }
    ;

// lexer
NEWLINE : '\r'? '\n';

WS :   (' '|'\t')+ -> skip  ;

ENTIER : ('0'..'9')+  ;

COMMENTAIRES : (('#' ~('\n'|'\r')*) | ('/''/' ~('\n'|'\r')*) | '/*'.*?'*/') -> skip;

TYPE : 'int' | 'double' ;

IDENTIFIANT
    :   ('a'..'z' | 'A'..'Z' | '_')('a'..'z' | 'A'..'Z' | '_' | '0'..'9')*
    ;

UNMATCH : . -> skip ;

