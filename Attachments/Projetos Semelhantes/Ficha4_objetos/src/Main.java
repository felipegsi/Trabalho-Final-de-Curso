import java.util.Arrays;

public class Main {
    public static void main(String[] args) {

        Pessoa[] amigos = tresAmigos();
        for (Pessoa amigo : amigos) {
            System.out.println(amigo);
        }

    }

    static Pessoa[] tresAmigos() {
        Pessoa[] amigos = new Pessoa[3];
        amigos[0] = new Pessoa("Felipe", "Silva");
        amigos[1] = new Pessoa("João", "Santos");
        amigos[2] = new Pessoa("Maria", "Oliveira");
        return amigos;
    }

}