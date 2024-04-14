public class Main {
    public static void main(String[] args) {
        //System.out.println(multiplica(4,3));
        System.out.println(tabuadaEmLinha(9,1));
     //   System.out.println(linhaDeAsteriscos(5));
      //  System.out.println(arvoreNatal(4));
    }
    static long multiplica(int n1, int n2){
        if (n1 <= 0){
            return 0;
        }
        return multiplica(n1 - 1, n2) + n2;
    }


    static String linhaDeAsteriscos(int dimensao){
        if(dimensao <= 0){
            return "";
        }
        return linhaDeAsteriscos(dimensao - 1) + "*";
    }



    static String arvoreNatal(int altura) {
        if (altura <= 0) {
            return "";
        }
        // Construa a árvore de cima para baixo, adicionando o '\n' antes das linhas, exceto para a primeira.
        String arvore = arvoreNatal(altura - 1);
        // Adicione o '\n' apenas se não for a primeira linha.
        if (!arvore.isEmpty()) {
            arvore += "\n";
        }
        // Adicione a linha de asteriscos da altura atual.
        arvore += linhaDeAsteriscos(altura);
        return arvore;
    }
    // Método que gera uma linha da tabuada para um dado número até o multiplicador 10.
    static String tabuadaEmLinha(int numero, int multiplicador) {
        // Condição de término da recursão: se o multiplicador é maior que 10, retorna uma string vazia.
        if (multiplicador > 10) {
            return "";
        }

        // Chamada à função `multiplica` para calcular o produto de `numero` e `multiplicador`.
        // O resultado é convertido para String e atribuído a `tabuada`.
        String tabuada = multiplica(numero, multiplicador) + "";

        // Se o multiplicador ainda é menor que 10, ou seja, se ainda não estamos na última chamada recursiva...
        if (multiplicador < 10){
            // ... concatena o resultado atual com uma vírgula e o resultado da próxima chamada recursiva.
            // A chamada recursiva incrementa o multiplicador em 1.
            tabuada += "," + tabuadaEmLinha(numero, multiplicador + 1);
        }

        // Retorna a string acumulada de `tabuada`, que contém a tabuada do `numero` até o multiplicador atual.
        return tabuada;
    }


}

