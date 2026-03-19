/* Javascript for file drag and drop zone */
var dropzone = document.getElementById('dropzone');
var dropzoneform = document.getElementById('dropzone-form');
var dropzone_input = document.querySelector('.dropzone-input');
var multiple = dropzone_input.getAttribute('multiple') ? true : false;
var fileList = document.querySelector('.file-list');

var allowedFileTypes = ['application/json', 'application/xml', 'text/xml'];

['drag', 'dragstart', 'dragend', 'dragover', 'dragenter', 'dragleave', 'drop'].forEach(function(event) {
  dropzoneform.addEventListener(event, function(e) {
    e.preventDefault();
    e.stopPropagation();
  });
});

/*
dropzone.addEventListener('dragover', function(e) {
  this.dropzone.add('dropzone-dragging');
}, false);

dropzone.addEventListener('dragenter', function(e) {
  this.dropzone.add('dropzone-dragging');
}, false);

dropzone.addEventListener('dragleave', function(e) {
  this.dropzone.remove('dropzone-dragging');
}, false);
*/

[ 'dragover', 'dragenter' ].forEach( event => dropzoneform.addEventListener(event, function(e) {
  dropzoneform.classList.add('dropzone-dragging');
}), false);

[ 'dragleave', 'dragend', 'drop' ].forEach( event => dropzoneform.addEventListener(event, function(e) {
  dropzoneform.classList.remove('dropzone-dragging');
}), false );

dropzoneform.addEventListener('drop', function (e) {
  /*
  var files = e.dataTransfer.files;
  var dataTransfer = new DataTransfer();
  
  var for_alert = "";
  Array.prototype.forEach.call(files, file => {
    const isSupported = allowedFileTypes.includes(file.type);
    if (isSupported) {
      for_alert += "# " + file.name +
		    " (" + file.type + " | " + file.size +
        " bytes)\r\n";
        dataTransfer.items.add(file);
    } else {
      return alert("# " + file.name + " of type " + file.type + " is not allowed.\r\n");
    }
    return false;
  });

  var filesToBeAdded = dataTransfer.files;
  dropzone_input.files = filesToBeAdded;
  updateFileList();
  alert(for_alert);
  */
  files = e.dataTransfer.files;
  Array.prototype.forEach.call(files, file => {
    const isSupported = allowedFileTypes.includes(file.type);
    if (!isSupported) {
      return alert("# " + file.name + " of type " + file.type + " is not allowed.\r\n");
    }
    return false;
  });
  dropzone_input.files = files;
  updateFileList();
  
}, false);

dropzone.addEventListener('click', function(e) {
  dropzone_input.click();
});

 function updateFileList() {

   const filesArray = Array.from(dropzone_input.files);
   if (filesArray.length > 1) {
                fileList.innerHTML = '<p>Selected files:</p><ul><li>' + filesArray.map(f => f.name).join('</li><li>') + '</li></ul>';
            } else if (filesArray.length == 1) {
                fileList.innerHTML = `<p>Selected file: ${filesArray[0].name}</p>`;
            } else {
                fileList.innerHTML = '';
            }
        }



