package ai.songb.elk;

import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/order")
@Slf4j
public class OrderController {

    @GetMapping("/{id}")
    public Order getOrder(@PathVariable Long id) {
        String orderNumber = "ORD" + System.currentTimeMillis();
        log.info("正在处理订单, orderNumber={}", orderNumber);
        // 模拟返回一个Order对象
        return new Order(
            id,
                orderNumber,
            "张三",
            99.99,
            "PENDING"
        );
    }
}