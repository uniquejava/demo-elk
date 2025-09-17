package ai.songb.elk;

public record Order(
    Long id,
    String orderNumber,
    String customerName,
    double amount,
    String status
) {
    // 这是一个record类，自动包含了全参数构造器、getter、equals()、hashCode()和toString()
}
