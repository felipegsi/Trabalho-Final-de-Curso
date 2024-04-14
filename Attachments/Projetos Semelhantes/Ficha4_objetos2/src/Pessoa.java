public class Pessoa {
    String nome;
    String apelido;
    Apartamento apartamento;

    public Pessoa(String nome, String apelido) {
        this.nome = nome;
        this.apelido = apelido;
    }
    public Pessoa(String nome, String apelido, Apartamento apartamento) {
        this.nome = nome;
        this.apelido = apelido;
        this.apartamento = apartamento;
    }
    public Pessoa(){
    }
    @Override
    public String toString() {
        if(apartamento == null){
            return nome + " " + apelido + " | Morada: desconhecida";
        }
        return nome + " " + apelido + " | " +  apartamento.toString();
    }
}

