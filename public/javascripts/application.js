function installAutocomplete(el, url, parentName) {
  var inplaceForm = $(el.id + "-inplaceeditor");
  var inplaceFields = inplaceForm.select("input");
  var inplaceField = inplaceFields[0];
  var update = $("auto_completer");
  new Ajax.Autocompleter(inplaceField, update, url, {method:'get', paramName: 'q'});
};

Event.observe(window, "load", function() {
  $$("table.core").each(function(table) {
    var coreControls = table.down(".core-controls");
    var aspectControls = table.down(".core-add-aspect");

    (function() {
      // Initial state
      var state = 'hidden';

      function transitionToShown() {
        // console.log('finishedShown -- state: %o, element: %o', state, table);
        if (state === 'showing') state = 'shown';
      }

      function transitionToHidden() {
        // console.log('finishedHidden -- state: %o, element: %o', state, table);
        if (state === 'hiding') state = 'hidden';
      }

      function transitionToHiding() {
        //new Effect.Fade(coreControls,   {afterFinish: transitionToHidden});
        //new Effect.Fade(aspectControls, {afterFinish: transitionToHidden});
        transitionToHidden;
        state = 'hiding';
      }

      function transitionToShowing() {
        new Effect.Appear(coreControls,   {afterFinish: transitionToShown});
        new Effect.Appear(aspectControls, {afterFinish: transitionToShown});
        state = 'showing';
      }

      Event.observe(table, "mouseover", function() {
        // console.log('over -- state: %o, element: %o', state, table);
        if (state === 'shown') {
          // NOP ;
        } else if (state === 'showing') {
          // NOP ;
        } else if (state === 'hiding') {
          transitionToShowing();
        } else if (state === 'hidden') {
          transitionToShowing();
        }
      });
      Event.observe(table, "mouseout",  function() {
        // console.log('out -- state: %o, element: %o', state, table);
        if (state === 'shown') {
          transitionToHiding();
        } else if (state === 'showing') {
          transitionToHiding();
        } else if (state === 'hiding') {
          // NOP ;
        } else if (state === 'hidden') {
          // NOP ;
        }
      });
    })();
  });

    $$(".editor.in-place-edit.card-kind").each(function(el) {
        Event.observe(el, "click", function() {
          // We can't install the autocompleter on click directly: we have to wait for a bit because there's other JS that creates the in-place-editor field
            installAutocomplete.delay(0.1, el, '/cards/auto/kind', '.kind-cell');
        });
    });

    $$(".editor.in-place-edit.card-name").each(function(el) {
        Event.observe(el, "click", function() {
          // We can't install the autocompleter on click directly: we have to wait for a bit because there's other JS that creates the in-place-editor field
            installAutocomplete.delay(0.1, el, '/cards/auto/name', '.name-cell');
        });
    });
});
