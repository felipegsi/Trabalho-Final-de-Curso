public class Main {
    public static void main(String[] args) {
        System.out.println("Hello world!");
        System.out.println(obtemChar(null, 1));
        System.out.println(somaDeN1aN2Multiplos5(5, 6));
        System.out.println(saoIguais(new char[] {'a'}, new char[] {'a', 'b'}, 0));
    }

    static char obtemChar(String s, int index) {

        if(s == null){
            return ' ';
        }

        if (index < 0 || index >= s.length()) {
            return ' ';
        }
        return s.charAt(index);
    }

    static int somaDeN1aN2Multiplos5(int n1, int n2) {
        if (n1 > n2) {
            return 0;
        }
        if (n1 % 5 == 0) {
            return n1 + somaDeN1aN2Multiplos5(n1 + 1, n2);
        }
        return somaDeN1aN2Multiplos5(n1 + 1, n2);
    }
      static boolean saoIguais(char[] a1, char[] a2, int pos){
        if (a1 == null || a2 == null){
            return false;
        }
        if (a1.length != a2.length){
              return false;
        }
        if (pos == a1.length){
            return true;
        }
        if (a1[pos] != a2[pos]){
            return false;
        }
        return saoIguais(a1, a2, pos + 1);
    }


}