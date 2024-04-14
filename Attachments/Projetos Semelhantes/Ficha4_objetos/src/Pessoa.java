public class Pessoa {
    String nome;
    String apelido;

    public Pessoa(String nome, String apelido) {
        this.nome = nome;
        this.apelido = apelido;
    }
    public Pessoa(){

    }

    @Override
    public String toString() {
        return "Bom dia, chamo-me " + nome + " " + apelido;
    }
}
