function installAutocomplete(el, url, parentName) {
  var inplaceForm = $(el.id + "-inplaceeditor");
  var inplaceFields = inplaceForm.select("input");
  var inplaceField = inplaceFields[0];
  var update = $("auto_completer");
  new Ajax.Autocompleter(inplaceField, update, url, {method:'get', paramName: 'q'});
};

// Number of seconds before we trigger the appear animation
var showDelay = 1.0;

// Duration of the appear animation
var appearDelay = 0.5;

// Number of seconds before we trigger the fade animation
var hideDelay = 10.0;

// Duration of the fade animation
var fadeDelay = 1.0;

var hideShowEngine = {
  'mouseover': {
    'hidden':     function(context) {
      (function() { context.transition("showTimeout"); }).delay(showDelay, context);
      return 'waitToShow';
    },
    'waitToShow': function(context) {
      return 'waitToShow';
    },
    'waitToHide': function(context) {
      return 'shown';
    },
    'hiding':     function(context) {
      (function() { context.transition("showTimeout"); }).delay(showDelay, context);
      return 'waitToShow';
    }
  },
  'mouseout':  {
    'waitToShow': function(context) {
      return 'hidden';
    },
    'showing':    function(context) {
      (function() { context.transition("hideTimeout"); }).delay(hideDelay, context);
      return 'waitToHide';
    },
    'shown':      function(context) {
      (function() { context.transition("hideTimeout"); }).delay(hideDelay, context);
      return 'waitToHide';
    },
  },
  'showTimeout': {
    'waitToShow': function(context) {
      new Effect.Appear(context.aspectControls, {duration: appearDelay});
      new Effect.Appear(context.coreControls,   {duration: appearDelay, afterFinish: function() { context.transition("showingDone"); }});
      return 'showing';
    },
    'waitToHide': function(context) {
      return 'waitToHide';
    },
  },
  'hideTimeout': {
    'waitToHide': function(context) {
      new Effect.Fade(context.aspectControls, {duration: fadeDelay});
      new Effect.Fade(context.coreControls,   {duration: fadeDelay, afterFinish: function() { context.transition("hidingDone"); }});
      return 'hiding';
    },
  },
  'showingDone': {
    'showing':    function(context) {
      return 'shown';
    },
  },
  'hidingDone': {
    'hiding':     function(context) {
      return 'hidden';
    },
  },
};

Event.observe(window, "load", function() {
  $$("table.core").each(function(table) {
    var context = {
      state          : 'hidden',
      coreControls   : table.down(".core-controls"),
      aspectControls : table.down(".core-add-aspect"),

      transition     : function(eventName) {
        fn = hideShowEngine[eventName][this.state];

        // Only call the transition function if there is one, else we keep the same state
        if (fn) this.state = fn(this);
      }
    };

    Event.observe(table, "mouseover", function() {
      context.transition("mouseover");
    });
    Event.observe(table, "mouseout",  function() {
      context.transition("mouseout");
    });
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
