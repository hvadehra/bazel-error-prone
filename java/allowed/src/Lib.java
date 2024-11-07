package java.allowed.src;

public class Lib implements MyInterface {

  public long someLong(long a) {
    return a << 1 | a << 2 & 0xFFFFL;
  }

}
