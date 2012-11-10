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

  setup: function(elmt){
    Codely.FileDrop.setup(elmt, Codely.ScriptReader.readFile);
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
      }

      reader.readAsText(file);
    }
  }
}

elmts = document.getElementsByClassName("script_drop");
for(var i=0; i<elmts.length; i++){
  Codely.ScriptReader.setup(elmts[i]);
}
