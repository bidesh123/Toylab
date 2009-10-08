function installAutocomplete(el, url, parentName) {
  var inplaceForm = $(el.id + "-inplaceeditor");
  var inplaceFields = inplaceForm.select("input");
  var inplaceField = inplaceFields[0];
  var update = $("auto_completer");
  new Ajax.Autocompleter(inplaceField, update, url, {method:'get', paramName: 'q'});
};

// Number of seconds before we trigger the appear animation
var showDelay = 2;

// Duration of the appear animation
var appearDelay = 0.0;

// Number of seconds before we trigger the fade animation
var hideDelay = 0.5;

// Duration of the fade animation
var fadeDelay = 2.0;

var hideShowEngine = {
  'mouseover': {
    'hidden':     function(context) {
      context.delay(showDelay, function() { context.transition("showTimeout") });
      return 'waitToShow';
    },
    'waitToHide': function(context) {
      context.cancelDelay();
      return 'shown';
    },
    'hiding':     function(context) {
      context.delay(showDelay, function() { context.transition("showTimeout") });
      return 'waitToShow';
    }
  },

  'mouseout':  {
    'waitToShow': function(context) {
      context.cancelDelay();
      return 'hidden';
    },
    'showing':    function(context) {
      context.delay(hideDelay, function() { context.transition("hideTimeout") });
      return 'waitToHide';
    },
    'shown':      function(context) {
      context.delay(hideDelay, function() { context.transition("hideTimeout") });
      return 'waitToHide';
    },
  },

  'showTimeout': {
    'waitToShow': function(context) {
      if(context.aspectControls) {new Effect.Appear(context.aspectControls, {duration: appearDelay})};
      new Effect.Appear(context.coreControls,   {duration: appearDelay, afterFinish: function() { context.transition("showingDone"); }});
      return 'showing';
    },
  },

  'hideTimeout': {
    'waitToHide': function(context) {
      if(context.aspectControls) {new Effect.Fade(context.aspectControls, {duration: fadeDelay})};
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

      // Executes a function after a timeout
      delay: function(delay, fn) {
        this.cancellableFunction = fn.delay(delay, this);
      },

      // Cancels a timeout that's been initiated, but only if there is one
      cancelDelay: function() {
        if (this.cancellableFunction) window.clearTimeout(this.cancellableFunction)
        this.cancellableFunction = null;
      },

      transition: function(eventName) {
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

    $$("input.editable_now", "textarea.editable_now", "select.editable_now").each(function(field) {
      Event.observe(field, "blur", function() {
        var id = field.id.split("_").last();
        new Ajax.Request("/cards/" + id, {
          method: 'put',
          parameters: {'card[name]': field.value, 'authenticity_token': $("rails.authtoken").innerHTML},
          onSuccess: function() {
            // TODO: hide spinner
          }
        });
      });
    });

    $$(".drag_handle").each(function(handle) {
      var el = handle.up("table.card");
      new Draggable(el, {revert: true, handle: handle, scroll: window});
    });

    $$(".drop-target").each(function(target) {
      Droppables.add(target, {
        hoverclass: 'drop-hover',
        onDrop: function(card, target, event) {
          var targetId = target.down("table.core").id;
          var cardId = card.down("table.core").id;
          new Ajax.Request("/reorders", {
            method: 'post',
            parameters: {
              'card_id': cardId.split("_").last(),
              'target_id': targetId.split("_").last(),
              'authenticity_token': $("rails.authtoken").innerHTML
            },
            onSuccess: function() {
              window.location.reload();
            }
          });
        }
      });
    });
});
