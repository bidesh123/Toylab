/*
window.location.replace('http://toylab.heroku.com/bump');
but can I NOT tell the server?
    what's the server got to do with whether an object is selected and how deep it is opened'
check_the_state_of_the_cookie('active');
document.cookie =
    'activity317=testcookie; expires=Thu, 2 Aug 2001 20:47:11 UTC; path=/';
document.cookie =
    'activity317=testcookie; expires=Thu, 2 Aug 2001 20:47:11 UTC; path=/';
0-off       white   normal    no menus      not selected;
1-auto      green   selected  hover_menus   selected;
2-on        orange  menu      stable_menus  selected;
3-custom    red     control   controls      selected;
*/

// Number of seconds before we trigger the appear animation
var appearDelay = 1.0;

// Duration of the appear animation
var appearDuration = 0.25;

// Number of seconds before we trigger the hide animation
var hideDelay = 2.5;

// Duration of the hide animation
var hideDuration = 4.0;

/*
var $j = jQuery.noConflict();
$j(document).ready(function(){
    alert("N'ajustez pas votre appareil");
    $j("a").click(function(event) {
        event.preventDefault()          ;
        $j(this).animate( {
            background: abc,
            color: #000,
            padding:100
          }          ,
          5000       ,
          function() {
          },
          { duration: 'slow',
            complete: function() {
              $(this).after('<div>Animation complete.</div>');
            }

        } ) ;
        alert("We control the horizontal")
     } );
} );
*/


var hideShowEngine = {
  'mouseover': {
    'hidden':     function(context) {
      context.delay(appearDelay, function() { context.transition("showTimeout") });
      return 'waitToShow';
    },
    'waitToHide': function(context) {
      context.cancelDelay();
      return 'shown';
    },
    'hiding':     function(context) {
      context.delay(appearDelay, function() { context.transition("showTimeout") });
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
    }
  },

  'showTimeout': {
    'waitToShow': function(context) {
      if(context.aspectControls) {new Effect.Appear(context.aspectControls, {duration: appearDuration})};
      new Effect.Appear(context.coreControls,   {
          duration: appearDuration,
          afterFinish: function() { context.transition("showingDone"); }});
      return 'showing';
    }
  },

  'hideTimeout': {
    'waitToHide': function(context) {
      if(context.aspectControls) {
        new     Effect.Parallel(
          [ new Effect.BlindUp( context.aspectControls               ,
            { duration: hideDuration                               } ) ,
            new Effect.BlindUp( context.coreControls                 ,
            { duration: hideDuration                               } ) ] ,
          {   afterFinish:
                function() {    context.transition("hidingDone");}   }   )
      }
      else {
        new     Effect.SlideUp( context.coreControls                      )
      };
      return 'hiding';
    }
  },

  'showingDone': {
    'showing':    function(context) {
      return 'shown';
    }
  },

  'hidingDone': {
    'hiding':     function(context) {
      return 'hidden';
    }
  }
};

Event.observe(window, "load", function() {
  $$("table.core").each(function(table) {
    var context = {
      state          : 'hidden',
      coreControls   : table.down(".core-controls"),
      aspectControls : table.down(".right-controls"),

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

function adjustRows (textarea) {
    if (document.all) {
        while (textarea.scrollHeight > textarea.clientHeight)
            textarea.rows++;
            textarea.scrollTop = 0;
        }
    else if (textarea.rows) {
        var lineBreaks = countLineBreaks(textarea.value);
        var rows = parseInt(textarea.rows);
        var wrap = textarea.getAttribute('wrap');
        if (lineBreaks > rows)
            textarea.rows = ++rows;
        else if (wrap.toLowerCase() == 'soft' || wrap.toLowerCase() == 'hard') {
            while (textarea.rows * textarea.cols <= textarea.value.length) {
                textarea.rows = ++rows;
            }
        }
    }
}

function installAutocomplete(el, url, parentName) {
  var inplaceForm = $(el.id + "-inplaceeditor");
  var inplaceFields = inplaceForm.select("input");
  var inplaceField = inplaceFields[0];
  var update = $("auto_completer");
  var cardId = $(el).up(".core-unit").id;
  var id = cardId.split("_").last();
  new Ajax.Autocompleter(inplaceField, update, url, {method:'get', paramName: 'q', parameters: 'parent_id=' + id});
};

