html 문서에서 radio 타입인 input 요소들이 선택되지 않았을 때는 value가 뭐로 잡힐까?

## Radio Input의 Value 동작
### 1. 선택되지 않은 상태
- **JavaScript에서 접근**: 선택되지 않은 radio input의 `value` 속성에 접근하면, HTML에서 정의된 `value` 속성값이 그대로 반환됩니다.
- **Form 제출 시**: 선택되지 않은 radio input들은 **form 데이터에 포함되지 않습니다**.

### 2. 예시

```html
<form>
  <input type="radio" name="color" value="red" id="red">
  <label for="red">빨강</label>
  
  <input type="radio" name="color" value="blue" id="blue">
  <label for="blue">파랑</label>
  
  <input type="radio" name="color" value="green" id="green">
  <label for="green">초록</label>
</form>
```

```javascript
// 아무것도 선택하지 않은 상태에서
const redRadio = document.getElementById('red');
console.log(redRadio.value); // "red" (HTML의 value 속성값)
console.log(redRadio.checked); // false

// 선택된 radio 찾기
const selectedRadio = document.querySelector('input[name="color"]:checked');
console.log(selectedRadio); // null (아무것도 선택되지 않음)
```

### 3. Form 제출 시 동작

```javascript
// FormData로 확인
const form = document.querySelector('form');
const formData = new FormData(form);

// 아무 radio도 선택하지 않은 경우
console.log(formData.get('color')); // null
console.log(formData.has('color')); // false
```

### 4. 선택된 값 확인하는 방법

```javascript
function getSelectedRadioValue(name) {
  const selected = document.querySelector(`input[name="${name}"]:checked`);
  return selected ? selected.value : null; // 또는 기본값
}

// 사용
const selectedColor = getSelectedRadioValue('color');
console.log(selectedColor); // 선택된 경우 해당 value, 미선택 시 null
```


### 핵심 포인트
- **개별 radio input의 `value` 속성**: 항상 HTML에서 정의된 값
- **선택 여부**: `checked` 속성으로 확인
- **Form 제출**: 선택된 radio만 서버로 전송됨
- **미선택 시 처리**: JavaScript에서 명시적으로 체크해야 함

따라서 radio input이 선택되지 않았을 때 "값이 없다"는 것은 form 제출 관점에서이고, 개별 요소의 `value` 속성 자체는 여전히 HTML에서 정의한 값을 가지고 있다.

## jQuery `.val()` 메서드의 동작
jquery를 이용해 입력된 text 값이나 선택된 radio value 를 가져왔을 때 입력되지 않은 text나 radio value는 어떤 값일까?

### 1. Text Input (입력되지 않은 경우)

```html
<input type="text" id="username" name="username">
<input type="text" id="email" name="email" value="default@email.com">
```

```javascript
// 아무것도 입력하지 않은 text input
console.log($('#username').val()); // "" (빈 문자열)

// value 속성이 있는 경우
console.log($('#email').val()); // "default@email.com"

// value 속성을 지우고 입력하지 않은 경우
$('#email').val('');
console.log($('#email').val()); // "" (빈 문자열)
```


### 2. Radio Input (선택되지 않은 경우)

```html
<input type="radio" name="gender" value="male" id="male">
<input type="radio" name="gender" value="female" id="female">
```

```javascript
// 개별 radio 요소의 value (선택 여부와 관계없이)
console.log($('#male').val()); // "male"
console.log($('#female').val()); // "female"

// 선택된 radio의 value 가져오기
console.log($('input[name="gender"]:checked').val()); // undefined (아무것도 선택되지 않음)

// 더 안전한 방법
const selectedGender = $('input[name="gender"]:checked').val();
console.log(selectedGender || 'none'); // 'none' (선택되지 않음)
```

### 3. 실제 사용 예시

```javascript
// Text input 값 확인
function getTextValue(selector) {
    const value = $(selector).val();
    return value; // 빈 문자열 또는 입력된 값
}

// Radio 선택값 확인
function getRadioValue(name) {
    const value = $(`input[name="${name}"]:checked`).val();
    return value; // undefined 또는 선택된 값
}

// 사용 예시
const username = getTextValue('#username');
if (username === '') {
    console.log('사용자명이 입력되지 않았습니다.');
}

const gender = getRadioValue('gender');
if (gender === undefined) {
    console.log('성별이 선택되지 않았습니다.');
}
```

### 4. Form 전체 데이터 수집

```javascript
// serialize() 사용
const formData = $('#myForm').serialize();
console.log(formData); // "username=&email=test%40email.com" 
// (빈 text는 포함되지만, 선택되지 않은 radio는 제외됨)

// serializeArray() 사용
const formArray = $('#myForm').serializeArray();
console.log(formArray);
// [
//   {name: "username", value: ""},
//   {name: "email", value: "test@email.com"}
//   // 선택되지 않은 radio는 포함되지 않음
// ]
```

### 5. 값 존재 여부 체크하는 실용적인 방법

```javascript
// Text input 값 체크
function hasTextValue(selector) {
    return $(selector).val().trim() !== '';
}

// Radio 선택 여부 체크
function hasRadioValue(name) {
    return $(`input[name="${name}"]:checked`).length > 0;
}

// 사용
if (!hasTextValue('#username')) {
    alert('사용자명을 입력해주세요.');
}

if (!hasRadioValue('gender')) {
    alert('성별을 선택해주세요.');
}
```

## 핵심 정리

| 요소 타입 | 입력/선택 안된 경우 | jQuery `.val()` 결과 |
|-----------|-------------------|-------------------|
| Text Input | 입력 안됨 | `""` (빈 문자열) |
| Radio Input | 개별 요소 접근 | HTML의 `value` 속성값 |
| Radio Input | `:checked` 셀렉터 사용 | `undefined` |

따라서 **text input**은 빈 문자열(`""`)을, **선택되지 않은 radio**는 `undefined`를 반환합니다.

## 그렇다면 선택되지 않은 radio 타입의 value를 가져오게 되면 undefined야?

### 1. 개별 Radio 요소에 직접 접근하는 경우

```html
<input type="radio" name="gender" value="male" id="male">
<input type="radio" name="gender" value="female" id="female">
```

```javascript
// 아무것도 선택하지 않은 상태에서
console.log($('#male').val());   // "male" (HTML의 value 속성값)
console.log($('#female').val()); // "female" (HTML의 value 속성값)

// 선택 여부와 상관없이 항상 해당 요소의 value 속성을 반환
```

### 2. `:checked` 셀렉터를 사용하는 경우

```javascript
// 아무것도 선택되지 않은 상태에서
console.log($('input[name="gender"]:checked').val()); // undefined

// 왜냐하면 선택된 요소가 없어서 jQuery 객체가 비어있기 때문
console.log($('input[name="gender"]:checked').length); // 0
```

### 3. 실제 테스트 예시

```javascript
// 테스트해보기
const $maleRadio = $('#male');
const $femaleRadio = $('#female');
const $checkedRadio = $('input[name="gender"]:checked');

console.log('Male radio value:', $maleRadio.val());        // "male"
console.log('Female radio value:', $femaleRadio.val());    // "female"
console.log('Checked radio value:', $checkedRadio.val());  // undefined
console.log('Checked radio length:', $checkedRadio.length); // 0

// 이제 male을 선택해보자
$('#male').prop('checked', true);

console.log('After selecting male:');
console.log('Checked radio value:', $('input[name="gender"]:checked').val()); // "male"
```

### 4. 더 명확한 비교

```javascript
// 방법 1: 특정 radio 요소의 value (항상 value 속성 반환)
$('#male').val()  // 항상 "male"

// 방법 2: 선택된 radio의 value (선택된 것만)
$('input[name="gender"]:checked').val()  // undefined (선택 안됨) 또는 선택된 값

// 방법 3: 안전한 방법
const selectedValue = $('input[name="gender"]:checked').val() || null;
```

## 정리

- **개별 radio 요소**에 `.val()` 사용 → **HTML의 value 속성값 반환** (선택 여부 무관)
- **`:checked` 셀렉터**와 함께 `.val()` 사용 → **undefined 반환** (선택된 요소가 없을 때)

따라서 "선택되지 않은 radio의 value"가 undefined인지는 **어떤 방식으로 접근하느냐**에 따라 달라진다.

## 또다른 질문 

`<input type="radio" name="gender" value="male" id="male">`
를 
`console.log($('#gender').val());`
로 가져오면 뭘까?

```javascript
console.log($('#gender').val()); // undefined
```

**undefined**다.

## 이유

`$('#gender')`는 **id가 "gender"인 요소**를 찾으려고 하는데, 아래의 HTML에서는:

```html
<input type="radio" name="gender" value="male" id="male">
```
- `name` 속성: "gender"
- `id` 속성: "male"

따라서 `id="gender"`인 요소가 존재하지 않기 때문에 jQuery는 빈 객체를 반환하고, 빈 객체에서 `.val()`을 호출하면 `undefined`가 반환된다.

## 올바른 접근 방법

```javascript
// 1. 실제 id로 접근
console.log($('#male').val()); // "male"

// 2. name 속성으로 접근
console.log($('input[name="gender"]').val()); // "male" (첫 번째 요소의 value)

// 3. 선택된 radio 찾기
console.log($('input[name="gender"]:checked').val()); // undefined (선택 안됨)
```

## 확인해보기

```javascript
console.log($('#gender').length);        // 0 (요소가 없음)
console.log($('#male').length);          // 1 (요소가 존재함)
console.log($('input[name="gender"]').length); // 1 (name으로는 찾을 수 있음)
```


따라서 `$('#gender').val()`은 존재하지 않는 요소에 접근하려고 해서 **undefined**를 반환한다.
