function installAutocomplete(el, url, parentName) {
  var inplaceForm = $(el.id + "-inplaceeditor");
  var inplaceFields = inplaceForm.select("input");
  var inplaceField = inplaceFields[0];
  var update = $("auto_completer");
  new Ajax.Autocompleter(inplaceField, update, url, {method:'get', paramName: 'q'});
};

var hideShowEngine = {
  'mouseover': {
    'hidden':     function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'waitToShow': function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'showing':    function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'shown':      function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'waitToHide': function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'hiding':     function(table, coreControls, aspectControls) {
      return 'hidden';
    }
  },
  'mouseout':  {
    'hidden':     function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'waitToShow': function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'showing':    function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'shown':      function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'waitToHide': function(table, coreControls, aspectControls) {
      return 'hidden';
    },
    'hiding':     function(table, coreControls, aspectControls) {
      return 'hidden';
    }
  },
};

Event.observe(window, "load", function() {
  $$("table.core").each(function(table) {
    (function() {
      // Initial state
      var state          = 'hidden';

      var coreControls   = table.down(".core-controls");
      var aspectControls = table.down(".core-add-aspect");

      Event.observe(table, "mouseover", function() {
        state = hideShowEngine["mouseover"][state](table, coreControls, aspectControls);
      });
      Event.observe(table, "mouseout",  function() {
        state = hideShowEngine["mouseout"][state](table, coreControls, aspectControls);
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
