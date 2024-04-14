import java.util.Arrays;

public class Main {
    public static void main(String[] args) {
        System.out.println("Hello world!");
        //System.out.println(f01(new int[]{1,2,3}, 5));
        //System.out.println(f02(new int[]{1,2,3,6,3,5,1,3,4}, 0));
        // System.out.println(soma(new int[]{1,-2,3}));
        // System.out.println(fMin(new int[]{1}, 0));
        //System.out.println(fProduct(new int[]{1,2,3}));
        // System.out.println(fCount(new int[]{1, 2, 3, 4, 5, 2, 5, 2}, 0));
        //System.out.println(contaLetra("teeste", 'e', 0));
        //System.out.println(contaLetraSubs("woejrwer", 'w'));
        //System.out.println(inverte("lipe"));
        //System.out.println(tira("felipfefe", 'f'));
        //System.out.println(vogais(new char[]{ 'f', 'b', 'q'}));

        int[] testArray = {2, 3,2,2};
        System.out.println(multiplicaDiferentes(testArray)); // Should output 120

        //System.out.println(contaPares(new int[]{1, 7, 5, 3}, 3));

    }

    static int somaArgExtra(int[] array, int numero) {

        if (array == null || numero >= array.length) {
            return 0;
        }

        return somaArgExtra(array, numero + 1) + array[numero];

    }


    static int somaCopy(int[] array) {
        if (array == null || array.length == 0) {
            return 0;
        }
        if (array.length == 1) {
            return array[0];
        }
        int[] arrayEsq = Arrays.copyOfRange(array, 0, array.length / 2);
        int[] arrayDir = Arrays.copyOfRange(array, array.length / 2, array.length);

        return somaCopy(arrayEsq) + somaCopy(arrayDir);
    }

    /* static int f02(int[] array, int numero){
     if(array == null || numero >= array.length){
         return 0;
     }
     if(numero == array.length - 1){
         return array[numero];
     }

     if(array[numero] > f02(array, numero + 1)){
         return array[numero];
     }else {
         return f02(array, numero + 1);
     }
 }*/
    static int fMin(int[] array, int index) {
        if (array == null || index >= array.length) {
            return 0;
        }

        if (index == array.length - 1) {
            return array[index];
        }

        if (array[index] < fMin(array, index + 1)) {
            return array[index];
        } else {
            return fMin(array, index + 1);
        }

    }


    static int soma(int[] array) {
        if (array == null || array.length == 0) {
            return 0;
        }
        if (array.length == 1) {
            return array[0];
        }
        int[] arrayEsq = Arrays.copyOfRange(array, 0, array.length / 2);
        int[] arrayDir = Arrays.copyOfRange(array, array.length / 2, array.length);

        return soma(arrayEsq) + soma(arrayDir);
    }


    static int fProduct(int[] array) {
        if (array == null || array.length == 0) {
            return 0;
        }

        if (array.length == 1) {
            return array[0];
        }

        int[] arrayEsq = Arrays.copyOfRange(array, 0, array.length / 2);
        int[] arrayDir = Arrays.copyOfRange(array, array.length / 2, array.length);
        return fProduct(arrayEsq) * fProduct(arrayDir);

    }


    static int fCount(int[] array, int index) {
        // Implement the function here.

        if (array == null || index > array.length) {
            return 0;
        }
        if (index == array.length - 1) {
            return array[index];
        }


        if (array[index] == 4) {
            return 1 + fCount(array, index + 1);
        } else {
            return fCount(array, index + 1);
        }
    }

    // com array de int sem argumento extra tem que ser com copy of range
    // com array de int com argumento extra tem que ser sem copy of range

    //STRING

    static int contaLetra(String palavra, char letra, int index) {

        if (index >= palavra.length()) {
            return 0;
        }
        if (palavra.charAt(index) == letra) {
            return 1 + contaLetra(palavra, letra, index + 1);
        } else {
            return contaLetra(palavra, letra, index + 1);
        }

    }

    static int contaLetraSubs(String palavra, char letra) {

        if (palavra.length() == 0) {
            return 0;
        }

        if (palavra.length() == 1) {
            if (palavra.charAt(0) == letra) {
                return 1;
            } else {
                return 0;
            }
        }

        String palavraEsq = palavra.substring(0, 1);
        String palavraDir = palavra.substring(1, palavra.length());


        return contaLetraSubs(palavraEsq, letra) + contaLetraSubs(palavraDir, letra);
    }

    static String inverte(String palavra) {

        if (palavra.isEmpty()) {
            return palavra;
        }
        if (palavra.length() == 1) {
            return palavra;
        }

        String palavraEsq = palavra.substring(0, 1);
        String palavraDir = palavra.substring(1);

        return inverte(palavraDir) + inverte(palavraEsq);

    }

    static String tira(String palavra, char letra) {

        if (palavra.isEmpty()) {
            return palavra;
        }
        if (palavra.length() == 1) {
            if (palavra.charAt(0) == letra) {
                return "";
            } else {
                return palavra;
            }
        }

        String palavraEsq = palavra.substring(0, 1);
        String palavraDir = palavra.substring(1);

        return tira(palavraEsq, letra) + tira(palavraDir, letra);

    }

    static Boolean vogais(char[] letras) {

        if (letras.length == 0) {
            return false;
        }
        char[] letraEsq = Arrays.copyOfRange(letras, 0, 1);
        char[] letraDir = Arrays.copyOfRange(letras, 1, letras.length);

        if (Character.toLowerCase(letraEsq[0]) == 'a' || Character.toLowerCase(letraEsq[0]) == 'e' ||
                Character.toLowerCase(letraEsq[0]) == 'i' || Character.toLowerCase(letraEsq[0]) == 'o' ||
                Character.toLowerCase(letraEsq[0]) == 'u') {
            return true;
        }
        return vogais(letraDir);
    }

    static int contaPares(int[] array, int index) {
        if (index >= array.length) {
            if (index > 1) {
                if ((array.length - index) % 2 == 0) {
                    return 1;
                }
            }

            return 0;
        }
        if (array[index] % 2 == 0) {
            return 1 + contaPares(array, index + 1);
        } else {
            return contaPares(array, index + 1);
        }
    }

    static int maiorCinco(int[] array, int index) {
      if (index >= array.length){
          return 0;
      }
      if (array[index] > 5){
          return 1 + maiorCinco(array, index + 1);
      }else{
          return maiorCinco(array,index + 1);
      }
    }


    static int multiplicaDiferentes(int[] array) {
        if (array.length == 0) {
            return 1;
        }
        if (array.length == 1) {
            return array[0];
        }

        Arrays.sort(array);

        // Copy the array except the first element for recursion
        int[] subArray = Arrays.copyOfRange(array, 1, array.length);

        if (array[0] == array[1]) {
            // Recursive call without the first element if it is a duplicate
            return multiplicaDiferentes(subArray);
        } else {
            // Recursive call and multiply the first element with the result from the rest of the array
            return array[0] * multiplicaDiferentes(subArray);
        }
    }

    public static boolean containsChar(String str, char ch) {
        // Verifica se a string está vazia
        if (str.isEmpty()) {
            return false;
        }
        // Verifica se o primeiro caractere da string é o caractere procurado
        if (str.charAt(0) == ch) {
            return true;
        }
        // Chama a função recursivamente com a substring que exclui o primeiro caractere
        return containsChar(str.substring(1), ch);
    }


    public static int countUppercaseLetters(String str) {
        // Caso base: se a string estiver vazia, retorna 0
        if (str.isEmpty()) {
            return 0;
        }

        // Divide a string em "esquerda" (primeiro caractere) e "direita" (restante da string)
        char left = str.charAt(0); // Primeiro caractere
        String right = str.substring(1); // Restante da string

        // Verifica se o caractere da esquerda é maiúsculo
        // Se for, adiciona 1 ao resultado da chamada recursiva com a parte direita
        // Se não, apenas chama a função recursivamente com a parte direita
        if (Character.isUpperCase(left)) {
            return 1 + countUppercaseLetters(right);
        } else {
            return countUppercaseLetters(right);
        }
    }



}