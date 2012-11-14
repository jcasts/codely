var Codely = {}

Codely.alert = function(message, type){
  var alert_elmt = Codely.newAlertElmt(type);
  var warn_text  = alert_elmt.children(".alert-text");
  var title      = "Warning";
  if(type) title = type.charAt(0).toUpperCase() + type.slice(1);
  warn_text.html("<b>"+title+":</b> "+message);

  $(".alert-wrapper").prepend(alert_elmt);
  alert_elmt.animate({top: '48px', "margin-bottom": '0px'}, 200);

  //Codely.clearAlertTimeout();
  Codely.alertTimeout = setTimeout(function(){
    Codely.dismissAlert(alert_elmt);
  },4000);
}

Codely.dismissAlert = function(elmt){
  //Codely.clearAlertTimeout();
  var alert_elmt = $(elmt);
  var zi = alert_elmt.css('z-index');
  alert_elmt.css('z-index', (zi - 1).toString());
  alert_elmt.animate({top: '0px'}, 300, function(){
    alert_elmt.detach();
  });
}

Codely.clearAlertTimeout = function(){
  if(Codely.alertTimeout) window.clearTimeout(Codely.alertTimeout);
  Codely.alertTimeout = null;
}

Codely.newAlertElmt = function(type){
  if(!type) type = "warning";
  var elmt = $( document.createElement('div') );
  elmt.addClass("alert alert-block alert-"+type);
  elmt.html('<button type="button" class="close">×</button><div class="alert-text"></div>');
  elmt.css('z-index', '100');

  var close_btn = elmt.children(".close");
  close_btn.click(function(){
    Codely.dismissAlert(elmt);
  });

  return elmt;
}


Codely.prompt = function(title, msg, buttons){
  if(!buttons){
    buttons = [{
      text: "OK",
      type: "primary",
      callback: Codely.dismissPrompt
    }];
  }

  $('#prompt .prompt-title').text(title);
  $('#prompt .prompt-msg').text(msg);
  var footer = $('#prompt .prompt-footer');
  footer.text("");

  var link = $(document.createElement('a'));
  link.attr("href", "#");
  link.addClass("btn");

  $.each(buttons, function(i, btn){
    var elmt = link.clone();
    if(btn.href) elmt.attr("href", btn.href);
    if(btn.type) elmt.addClass("btn-"+btn.type);
    if(btn.callback){
      elmt.click(btn.callback);
    } else {
      elmt.click(Codely.dismissPrompt);
    }

    elmt.text(btn.text);
    footer.append(elmt);
  });

  $('#prompt').modal();
}

Codely.dismissPrompt = function(callback){
  $('#prompt').modal("hide");
}


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
      var file = evt.dataTransfer.files[0];
      evt.target.callback(evt.target, file);
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

  setupDrop: function(elmt, callback){
    Codely.FileDrop.setup(elmt, Codely.ScriptReader.readFile);
    elmt.onscript = callback;
  },


  setupBrowse: function(elmt, callback){
    elmt.addEventListener('change', Codely.ScriptReader.selectFile, false);
    elmt.onbrowsed = callback;
  },


  selectFile: function(evt){
    var files = evt.target.files;
    if(evt.target.onbrowsed) evt.target.onbrowsed(files[0]);
  },


  readFile: function(elmt, file){
    if(file.size > Codely.ScriptReader.maxSize){
      Codely.alert("<em>'"+file.name+"</em> is larger than 1Mb.", "error");

    } else if(!file.type.match('text.*')){
      var filetype = '';
      if(file.type) filetype = "<em>'"+file.type+"'</em> ";
      Codely.alert(
        "Unexpected file-type "+filetype+
        "for file <em>'"+file.name+"'</em>.",
        "error"
      );
      
    } else {
      var reader = new FileReader();
      reader.onload = function(ev){
        elmt.value = ev.target.result;
        elmt.focus();
        if(elmt.onscript) elmt.onscript(file);
      }

      reader.readAsText(file);
    }
  }
}

scr      = document.getElementById("scriptarea");
filename = document.getElementById("appendedInputButton");

if(scr){
  Codely.ScriptReader.setupDrop(scr, function(file){
    filename.value = file.name;
    $.ajax('/lang', {
      type: "POST",
      data: {filename: file.name},
      success: function(str){
        $('#lang').val(str);
      }
    });
  });

  browser = document.getElementById('browse-func');
  Codely.ScriptReader.setupBrowse(browser, function(file){
    Codely.ScriptReader.readFile(scr, file);
  });
}


//Fake browse button
$("#browse-btn").click(function(e){
  var evt = document.createEvent("MouseEvents");
  evt.initEvent("click", true, false);
  browser.dispatchEvent(evt);
});


//Prevent textarea tabs
$("textarea").keydown(function(e){
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


$("#delete-btn").click(function(e){
  Codely.prompt("Warning", "Do you really want to delete this paste?", [
    {text: "Cancel"},
    {text: "Delete", type: "danger", callback: function(e){
      $('#delete-paste').submit();
     }
    }
  ]);
});
