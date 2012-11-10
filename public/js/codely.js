var Codely = {}

Codely.FileDrop = {
  setup: function(elmt, callback){
    elmt.addEventListener('dragover', Codely.FileDrop.dragover, false);
    elmt.addEventListener('drop', Codely.FileDrop.drop, false);
    elmt.callback = callback;
  },

  dragover: function(evt){
    evt.stopPropagation();
    evt.preventDefault();
    evt.dataTransfer.dropEffect = 'copy';
  },

  drop: function(evt){
    evt.stopPropagation();
    evt.preventDefault();

    if(evt.target.callback){
      var files = evt.dataTransfer.files;
      for(var i=0; i<files.length; i++){
        evt.target.callback(evt.target, files[i]);
      }
    }

/*
      f.name
      f.type
      f.size
      f.lastModifiedDate
      f.lastModifiedDate.toLocaleDateString()
*/
  }
}


Codely.ScriptReader = {
  maxSize: (1024 * 1024),

  errors: [],

  setup: function(elmt, callback){
    Codely.FileDrop.setup(elmt, Codely.ScriptReader.readFile);
    elmt.onscript = callback;
  },

  readFile: function(elmt, file){
    if(file.size > Codely.ScriptReader.maxSize){
      Codely.ScriptReader.errors.push(
        file.name + " is larger than 1Mb"
      );

    } else if(!file.type.match('text.*')){
      Codely.ScriptReader.errors.push(
        file.name + " is not a text file"
      );

    } else {
      var reader = new FileReader();
      reader.onload = function(ev){
        elmt.value = ev.target.result;
        elmt.change();
        elmt.focus();
        if(elmt.onscript) elmt.onscript(file);
      }

      reader.readAsText(file);
    }
  }
}

elmt = document.getElementById("scriptarea");
Codely.ScriptReader.setup(elmt);

//Prevent textarea tabs
$("textarea").keydown(function(e) {
  if(e.keyCode === 9) { // tab was pressed
    // get caret position/selection
    var start = this.selectionStart;
    var end = this.selectionEnd;
    var tab = ((start-1) % 2 === 0) ? "  " : " ";

    var $this = $(this);
    var value = $this.val();

    // set textarea value to: text before caret + tab + text after caret
    $this.val(value.substring(0, start)
                + tab
                + value.substring(end));

    // put caret at right position again (add one for the tab)
    this.selectionStart = this.selectionEnd = start + tab.length;

    // prevent the focus lose
    e.preventDefault();
  }
});
