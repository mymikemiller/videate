/* Slide 12 (#5) */
window.addEventListener("load", function () {
  console.log("in load");
  const form = document.getElementById('email-form');
  form.addEventListener("submit", function (e) {
    console.log("event happened");
    e.preventDefault();
    const data = new FormData(form);
    const action = e.target.action;
    document.getElementById('name').value = "";
    document.getElementById('email').value = "";
    fetch(action, {
      method: 'POST',
      body: data,
    })
      .then(() => {
        alert("You're signed up. We'll be in touch!");
      })
  });
});
