import credits from 'ic:canisters/credits';

credits.greet(window.prompt("Enter your name:")).then(greeting => {
  window.alert(greeting);
});
