public class Main {
    public static void main(String[] args) {

        Pessoa[] amigos = novosAmigos();
        for (Pessoa amigo : amigos) {
            System.out.println(amigo);
        }
    }


    static Pessoa[] novosAmigos() {
        Pessoa[] amigos = new Pessoa[3];
        amigos[0] = new Pessoa("Felipe", "Silva", new Apartamento("Rua da Paz", 123, "Porto", "Portugal"));
        amigos[1] = new Pessoa("João", "Santos", new Apartamento("Rua", 123, "Porto", "Portugal"));
        amigos[2] = new Pessoa("Maria", "Oliveira");
        return amigos;
    }
}