```javascript
const responseJson = call(request); // DB 조회가 이루어졌다고 가정하고

if (responseJson === undefined) { // 일종의 조건을 걸며 조회 결과를 검증하고
    //...
} 

deliveryData = responseJson.data;
shippingCompany = deliveryData.shipping_company;

if (shippingCompany) {
    // $('input[name=shippingCompany]') 가 지칭하는게 db값으로 체크하려는 라디오타입의 input 요소라면
    $('input[name=shippingCompany][value="' + shippingCompany + '"]').prop('checked', true);
}
```

라디오 버튼을 선택하려면 `prop('checked', true)`를 사용하면 된다.