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
        { $code += "  JUMP Start\n"; }
        NEWLINE*

        (fonction { $code += $fonction.code; })*
        NEWLINE*

        { $code += "LABEL Start\n"; }
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

    | logique
        { $code = $logique.code; }

    | operateur
        { $code = $operateur.code; }

    | condition
        { $code = $condition.code; }

    | boucle
        { $code = $boucle.code; }

    | bloc
        { $code = $bloc.code; }

    | ifCondition
        { $code = $ifCondition.code; }

    | finInstruction
    ; 

args returns [ String code, int size] @init{ $code = new String(); $size = 0; }
    : ( expression 
    {
        $code = $expression.code;
        $size++;
    }
    ( ',' expression
    {
        $code += $expression.code;
        $size++;
    }
    )*
      )?
    ;

expression returns [ String code, String type ]
    :   '-' expression {$code = "PUSHI 0\n" + $expression.code + "SUB\n";}
    |   g=expression op=('*'|'/'|'%') d=expression {$code = evalexpr($g.code, $op.text, $d.code);}
    |   g=expression op=('+'|'-') d=expression  {$code = evalexpr($g.code, $op.text, $d.code);}
    | '(' a=expression ')' { $code = $a.code;}
    |   ENTIER  {$code = "PUSHI " + $ENTIER.text+"\n";}
    |   IDENTIFIANT  
        {
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            if(vi.scope == VariableInfo.Scope.PARAM){
                $code = "PUSHL "+vi.address+"\n";
            }else{
                $code = "PUSHG "+vi.address+"\n";
            }
            
        }
    | COMMENTAIRES
    | IDENTIFIANT '(' args ')'                  // Appel de fonction
        {
            $code = $args.code;
            $code += "CALL "+$IDENTIFIANT.text+"\n";
            for(int i=0;i<$args.size;i++){$code+="POP\n";}

        }
    ;

finInstruction : ( NEWLINE | ';' )+ ;

decl returns [ String code ]
    :  TYPE IDENTIFIANT '=' expression finInstruction
        {  
            tablesSymboles.addVarDecl($IDENTIFIANT.text, $TYPE.text);
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = "PUSHI 0\n";
            $code += $expression.code;
            if(vi.scope == VariableInfo.Scope.PARAM){
                $code += "STOREL ";
            }else{
                $code += "STOREG ";
            }
            $code += vi.address + "\n";
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
            $code =  $expression.code;
            if(vi.scope == VariableInfo.Scope.PARAM){
                $code += "STOREL ";
            }else{
                $code += "STOREG ";
            }
            $code += vi.address + "\n";
        }

    |   IDENTIFIANT op=('+='|'-='|'*=') expression
        {  
            VariableInfo vim = tablesSymboles.getVar($IDENTIFIANT.text);
             if(vim.scope == VariableInfo.Scope.PARAM){
                $code = "PUSHL ";
            }else{
                $code = "PUSHG " ;
            }
            $code += vim.address + "\n";
            $code += $expression.code;

            if($op.text.equals("+=")){
                $code += "ADD\n";
            } else if($op.text.equals("-=")){
                $code += "SUB\n";
            } else if($op.text.equals("*=")){
                $code += "MUL\n";
            }
                
            if(vim.scope == VariableInfo.Scope.PARAM){
                $code += "STOREL ";
            }else{
                $code += "STOREG ";
            }
            $code += vim.address + "\n";
        }
    ;



input returns [ String code ]
    : 'input' '(' IDENTIFIANT ')' 
        {  
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = "READ\n"; 
             if(vi.scope == VariableInfo.Scope.PARAM){
                $code += "STOREL ";
            }else{
                $code += "STOREG ";
            }
            $code += vi.address + "\n";
        }
    ;


output returns [ String code ]
    : 'output' '(' IDENTIFIANT ')' 
        {  
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            if(vi.scope == VariableInfo.Scope.PARAM){
                $code = "PUSHL ";
            }else{
                $code = "PUSHG ";
            }
            $code += vi.address;
            $code += "\nWRITE\n";
            $code += "POP\n";

        }

    | 'output' '(' expression ')' 
        {  
            $code = $expression.code;
            $code += "WRITE\n";
            $code += "POP\n";
        }
    ;

bloc returns[ String code ]
@init{ $code = new String(); }
    : '{' NEWLINE? (instruction { $code += $instruction.code; })* '}' NEWLINE*
    ;


condition returns [String code]
    : 'True'  { $code = "PUSHI 1\n"; }
    | 'False' { $code = "PUSHI 0\n"; }
    | a = expression operateur b = expression
        {
            String boucle1 = newLabel();
            String exit = newLabel();
            $code = $a.code;
            $code += $b.code;
            $code += $operateur.code;
            $code += "JUMPF "+boucle1+"\n";
            $code += "PUSHI 1\n";
            $code += "JUMP "+exit+"\n";
            $code += "LABEL "+ boucle1 + "\n";
            $code += "PUSHI 0\n";
            $code += "LABEL "+exit+"\n";
        }
    | '(' condition ')' { $code = $condition.code; }

    | d = condition 'and' e = condition  // Ajout de AND
        {
            $code = $d.code + $e.code + "MUL\n"; 
        }
    | f = condition 'or' g = condition  // Ajout de OR
        {
            $code = $f.code + $g.code + "ADD\n";
        }
    | 'not' c = condition  // Ajout de NOT
        {
            String boucle1 = newLabel();
            String exit = newLabel();
            $code = $c.code;
            $code += "PUSHI 0\n";
            $code += "EQUAL \n";
            $code += "JUMPF "+boucle1+"\n";
            $code += "PUSHI 1\n";
            $code += "JUMP "+exit+"\n";
            $code += "LABEL "+ boucle1 + "\n";
            $code += "PUSHI 0\n";
            $code += "LABEL "+exit+"\n";
        }
    ;

operateur returns [String code]
    : '==' { $code = "EQUAL\n"; }
    | '!=' { $code = "NEQ\n"; }
    | '<>' { $code = "NEQ\n"; }
    | '>'  { $code = "SUP\n"; }
    | '>=' { $code = "SUPEQ\n"; }
    | '<' { $code = "INF\n"; }
    | '<=' { $code = "INFEQ\n"; }

    ;


logique returns [String code]
    : 'not' logique { $code = $logique.code + "PUSHI 0\nEQUAL\n"; }
    | a=logique 'and' b=logique  { $code = $a.code + $b.code + "MUL\n"; }
    | a=logique 'or' b=logique  { $code = $a.code + $b.code + "PUSHI 0\nSUP\n"; }
    | '(' logique ')'{ $code = $logique.code; }
    ;

boucle returns [ String code ] 
    : 'while' '(' condition ')' a = instruction
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
    |'for' '(' c= assignation ';' condition ';' b=assignation ')' instruction
        {
            String debutFor = newLabel();
            String exit = newLabel();

            $code = $c.code;
            $code += "LABEL " + debutFor + "\n";
            $code += $condition.code;
            $code += "JUMPF "+ exit + "\n";
            $code += $instruction.code;
            $code += $b.code;
            $code += "JUMP "+ debutFor + "\n";
            $code += "LABEL "+ exit + "\n";
        }
    ;

ifCondition returns [ String code ]
    : 'if' '(' condition ')' a = instruction 'else' b = instruction
        {
            String elseArea = newLabel();
            String exit = newLabel();

            $code = $condition.code;
            $code += "JUMPF "+elseArea + "\n";
            $code += $a.code;
            $code += "JUMP "+exit+"\n";
            $code += "LABEL "+elseArea + "\n";
            $code += $b.code;
            $code += "JUMP "+exit+"\n"; 
            $code += "LABEL "+exit+"\n";
        }
    | 'if' '(' condition ')' 'then' a = instruction
        {
            String exit = newLabel();

            $code = $condition.code;
            $code += "JUMPF "+exit + "\n";
            $code += $a.code;
            $code += "JUMP "+exit+"\n";
            $code += "LABEL "+exit+"\n";
        }
    | 'if' '(' condition ')' 'then' a = instruction 'else' b = instruction
        {
            String exit = newLabel();
            String elseArea = newLabel();

            $code = $condition.code;
            $code += "JUMPF "+elseArea + "\n";
            $code += $a.code;
            $code += "JUMP "+exit+"\n";
            $code += "LABEL "+elseArea + "\n";
            $code += $b.code;
            $code += "JUMP "+exit+"\n";
            $code += "LABEL "+exit+"\n";
        }
    ;

params
    : TYPE IDENTIFIANT
        {
            tablesSymboles.addParam($IDENTIFIANT.text,"int");
        }
        ( ',' TYPE IDENTIFIANT
            {
                tablesSymboles.addParam($IDENTIFIANT.text,"int");
            }
        )*
    ;


fonction returns [ String code ] @init{ tablesSymboles.enterFunction(); } @after{ tablesSymboles.exitFunction(); }
    :
    TYPE IDENTIFIANT 
        {
            tablesSymboles.addFunction($IDENTIFIANT.text, $TYPE.text);
        }
        '('  params ? ')' bloc
        {
            $code = "LABEL " + $IDENTIFIANT.text + "\n";
            $code += $bloc.code;
            $code += "RETURN\n"; 
        } 
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

