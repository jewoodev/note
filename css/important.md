레거시 프로젝트에서 상속하는 여러 css 때문에 라디오 버튼이 렌더링되지 않는 문제가 있었다. 기존 스타일이 무너질 수 있기 때문에 그런 css 스타일을 손대는 것은 지향하려 했다. 
이런 때에 `!important`를 사용하면 좋다. 

그런데 모달 창에 `!important`를 사용해 `visibility` 같은 가시성 설정을 덮어씌우면 모달 창을 열지 않은 상태에서도 화면에 모달 창의 요소들이 겹쳐보이는 문제가 생긴다. 

```css
/* 이런 스타일을 적용하면 */
.modal_example .example_inner ul li input[type="radio"] {
    display: inline-block !important;
    visibility: visible !important;
    /* ... 기타 !important 스타일들 */
}
```
이런 식으로 작성하면 겹쳐보일 거다. 모달 창이 열려야 보이는 관계성 마저 덮어씌워버리기 때문이다. 따라서 모달이 visible 상태일 때만 html 요소들이 표시되도록 설정해야 한다. 

```css
div.modal_shipping.modal-visible .shipping_inner ul li input[type="radio"] {
    -webkit-appearance: radio !important;
    -moz-appearance: radio !important;
    appearance: radio !important;
    width: 16px !important;
    height: 16px !important;
    margin: 0 8px 0 0 !important;
    padding: 0 !important;
    visibility: visible !important;
    display: inline-block !important;
    opacity: 1 !important;
    position: relative !important;
    left: auto !important;
    top: auto !important;
    z-index: 1 !important;
    border: none !important;
    background: transparent !important;
}

/* 모달이 보일 때만 라벨 표시 */
div.modal_shipping.modal-visible .shipping_inner ul li label {
    display: inline-block !important;
    margin-right: 20px !important;
    font-size: 16px !important;
    color: #041127 !important;
    cursor: pointer !important;
    visibility: visible !important;
    opacity: 1 !important;
}

/* 모달이 보일 때만 입력 필드 표시 */
div.modal_shipping.modal-visible .shipping_inner ul li input[type="number"] {
    border-radius: 5px;
    border: 1px solid #dbdbdb;
    width: 320px;
    height: 40px;
    line-height: 40px;
    color: #777777;
    font-size: 16px;
    font-family: 'NotoSansKR-Regular';
    outline: none;
    padding: 0 12px;
    display: block !important;
    visibility: visible !important;
}
```