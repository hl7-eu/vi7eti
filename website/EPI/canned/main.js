/*=============== accordion ===============*/
const accordionItem = document.getElementsByClassName("accordion__item");
const accordionHeader = document.getElementsByClassName("accordion__header");
const accordionContent = document.getElementsByClassName("accordion__content");

for (let i = 0; i < accordionItem.length; i++) {
    /* add a click function to the header area */
    accordionHeader[i].addEventListener("click", (e) => {
        if(accordionItem[i].classList.contains('accordion__open')){
            accordionItem[i].classList.remove('accordion__open')
            accordionContent[i].style.display = "none";
        } else {
            accordionItem[i].classList.add('accordion__open')
            accordionContent[i].style.display = "block";
        }
        /*  set focus */
        accordionContent[i].style.focus();
        e.stopPropagation();
        /* close all other accordions */
        for (let j = 0; j < accordionItem.length; j++) {
            if (j != i) {
               accordionItem[j].classList.remove("accordion__open");
               accordionContent[j].style.display = "none";
            }
        }
        /* Open parent accordion */
        let recursiveNode = accordionItem[i];
        while( (recursiveNode = recursiveNode.parentNode) ){
            if (recursiveNode.classList && recursiveNode.classList.contains('accordion__item')) {
                recursiveNode.classList.add("accordion__open");
                let recursiveNodeChildren = recursiveNode.childNodes;
                for(let j = 0; j < recursiveNodeChildren.length; j++) {
                   let childNode = recursiveNodeChildren[j];
                   if (childNode.classList && childNode.classList.contains('accordion__content')) {
                       childNode.style.display = "block";
                       break;
                   }
                }
            }
        }
    }
  );

}

/*  open all accordions (without click) that have the corresponding class */
for (let i = 0; i < accordionItem.length; i++) {
  if(accordionItem[i].classList.contains('accordion__initially__open')){
    accordionItem[i].classList.remove('accordion__initially__open')
    accordionItem[i].classList.add('accordion__open')
    accordionContent[i].style.display = "block";
  }
}

/*=============== source popup window ===============*/
function togglePopup() {
  const popDialog =
    document.getElementById(
      "popupDialog"
    );
  popDialog.style.visibility =
    popDialog.style.visibility ===
      "visible"
      ? "hidden"
      : "visible";
}

function loadJSON(filepath, callback) {   
  var xobj = new XMLHttpRequest();
  xobj.overrideMimeType("application/json");
  xobj.open('GET', filepath, true);
  xobj.onreadystatechange = function () {
        if (xobj.readyState == 4 && xobj.status == "200") {
          // Required use of an anonymous callback as .open will NOT return a value but simply returns undefined in asynchronous mode
          callback(xobj.responseText);
          // init(xobj.responseText)
        }
  };
  xobj.send(null);  
}