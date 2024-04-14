public class Apartamento {
    String rua;
    int numero;
    String localidade;
    String pais;

    public Apartamento(String rua, int numero, String localidade, String pais) {
        this.rua = rua;
        this.numero = numero;
        this.localidade = localidade;
        this.pais = pais;
    }
    @Override
    public String toString() {
        return rua + " " + numero + ", " + localidade + ", " + pais;
    }
}
