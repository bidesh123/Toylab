
Element.addMethods({
 textNodes: function(element){
                        alert(this.nodeName");
   return $A(this.childNodes).select( function(child){
       return this.nodeType == 3 || $.nodeName(this, "br");
   } );
 }
});

function showArgs() {
  alert($A(arguments).join(', '));
}

function getBodyTag() {
    window.frames["tgt_frame"].document.getElementsByTagName( "*" ).item(0).nodeType();
}

function editpage() {
                        alert("1 bod.nodeName");
    var innerdocument = window.frames["tgt_frame"].document;
    var bod = innerdocument.getElementsByTagName("body").item(0);
    if (bod){
                        alert("3 gotta bod");
        var txts = bod.textNodes();
                        alert(txts.length);
                        alert("4");
                        alert( typeof(txts) );
      for (txt in txts) {
      }
                        alert("6 Total Number of Texts Found: " + txts.length);
    }
}


// examples, junk
//
// function isNode(o){ //Returns true if it is a DOM node
function workingon() {
    return (
        typeof  Node === "object" ? o instanceof Node :
            typeof o === "object" && typeof o.nodeType === "number" && typeof o.nodeName==="string"
    );

    //Returns true if it is a DOM element
    function isElement(o){
      return (
        typeof HTMLElement === "object" ? o instanceof HTMLElement : //DOM2
        typeof o === "object" && o.nodeType === 1 && typeof o.nodeName==="string"
      );
    }
    var innerdocument = window.frames["tgt_frame"].document;

    var editing  = false;

    if (window.frames["tgt_frame"].document.getElementById && window.frames["tgt_frame"].document.createElement) {
            var butt = window.frames["tgt_frame"].document.createElement('BUTTON');
            var buttext = window.frames["tgt_frame"].document.createTextNode('Ready!');
            butt.appendChild(buttext);
            butt.onclick = saveEdit;
    }

    function catchIt(e) {
        alert("got it");
            if (editing) return;
            if (!window.frames["tgt_frame"].document.getElementById || !window.frames["tgt_frame"].document.createElement) return;
            if (!e) var obj = window.event.srcElement;
            else var obj = e.target;
            while (obj.nodeType != 1) {
                    obj = obj.parentNode;
            }
            if (obj.tagName == 'TEXTAREA' || obj.tagName == 'A') return;
            while (obj.nodeName != 'P' && obj.nodeName != 'HTML') {
                    obj = obj.parentNode;
            }
            if (obj.nodeName == 'HTML') return;
            var x = obj.innerHTML;
            var y = window.frames["tgt_frame"].document.createElement('TEXTAREA');
            var z = obj.parentNode;
            z.insertBefore(y,obj);
            z.insertBefore(butt,obj);
            z.removeChild(obj);
            y.value = x;
            y.focus();
            editing = true;
    }

    function saveEdit() {
            var area = window.frames["tgt_frame"].document.getElementsByTagName('TEXTAREA')[0];
            var y = window.frames["tgt_frame"].document.createElement('P');
            var z = area.parentNode;
            y.innerHTML = area.value;
            z.insertBefore(y,area);
            z.removeChild(area);
            z.removeChild(window.frames["tgt_frame"].document.getElementsByTagName('button')[0]);
            editing = false;
    }

    window.frames["tgt_frame"].document.onclick = catchIt;

    function getAllTags() {
        var arr = new Array();
        arr = document.getElementsByTagName( "*" );

        alert("Total Number of HTML Elements Found: " + document.getElementsByTagName( "*" ).length);

        for(var i=0; i < arr.length; i++)
        {
            var tagName = document.getElementsByTagName( "*" ).item(i).nodeName;

            switch (tagName)
            {
                case "DIV":
                    var tagObj = document.getElementsByTagName( "*" ).item(i);
                    alert("TagName: " + tagName + "\n\ninnerText:\n" + tagObj.innerHTML);
                    break;

                case "SPAN":
                    var tagObj = document.getElementsByTagName( "*" ).item(i);
                    alert("TagName: " + tagName + "\n\ninnerText:\n" + tagObj.innerHTML);
                    break;

                case "P":
                    var tagObj = document.getElementsByTagName( "*" ).item(i);
                    alert("TagName: " + tagName + "\n\ninnerText:\n" + tagObj.innerHTML);
                    break;

                default:
            }
        }
    }
}

