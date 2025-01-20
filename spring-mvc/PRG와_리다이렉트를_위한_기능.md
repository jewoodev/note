# PRG Post/Redirect/Get

Post 요청을 처리한 후 뷰를 렌더링하는 것으로 컨트롤러 로직을 마무리하면 Post 요청을 보낸 후에 새로고침할 때마다 같은 데이터로 Post 요청이 재차 날아간다.

왜냐하면 새로고침은 마지막으로 전송한 요청을 그대로 다시 보내는 것을 수행하는 것이기 때문이다. 

이 문제는 PRG로 해결할 수 있다. Post 요청을 처리한 후 Get 요청을 하는 URL로 redirect를 거는 것으로 컨트롤러 로직을 마무리 하는 것이다. 이렇게 하면 새로고침할 때 더이상 동일한 Post 요청이 전송되지 않고 Get 요청이 날아가게 된다.

## RedirectAttributes

리다이렉트를 할 땐 리다이렉트 URL을 인코딩할 필요가 있거나 쿼리 파라미터를 주기 위한 기능이 필요하다. 스프링 MVC는 RedirectAttributes 인터페이스로 그런 기능들을 제공한다.

```java
@PostMapping("/add")
public String add(Product product, RedirectAttributes redirectAttributes) {
    Product forSave = productRepository.save(product);
    redirectAttributes.addAttribute("productId", forSave.getId());
    redirectAttributes.addAttribute("save_result_status", true);
    return "redirect:/products/{productId}";
}
```

위의 예시에서 `productId`는 pathVariable으로 바인딩되고 `save_result_status`는 쿼리 파라미터로 처리된다.