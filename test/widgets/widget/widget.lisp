
(in-package :weblocks-test)

(deftestsuite widgets/widget/widget-suite (weblocks-suite print-upcase-suite)
  ())

;;; test defwidget
(deftest defwidget-1
    (macroexpand-1
     '(defwidget foo (bar)
       ((slot1 :initarg :slot1) (slot2 :initform nil))))
  (progn
    (defclass foo (bar)
      ((slot1 :initarg :slot1)
       (slot2 :initform nil))
      (:metaclass widget-class))
    (defmethod per-class-dependencies append ((weblocks::obj foo))
       (declare (ignore weblocks::obj))
       (weblocks::dependencies-by-symbol (quote foo))))
  t)

(deftest defwidget-2
    (macroexpand-1
     '(defwidget foo ()
       ((slot1 :initarg :slot1) (slot2 :initform nil))))
  (progn
    (defclass foo (widget)
      ((slot1 :initarg :slot1)
       (slot2 :initform nil))
      (:metaclass widget-class))
    (defmethod per-class-dependencies append ((weblocks::obj foo))
      (declare (ignore weblocks::obj))
      (weblocks::dependencies-by-symbol (quote foo))))
  t)


;;; test widget-dependencies
(addtest widget-dependencies-1
  (ensure-same (values-list
		(mapcar #'dependency-url
			(dependencies (make-instance 'navigation))))
	       (values (puri:uri "/pub/stylesheets/menu.css")
		       (puri:uri "/pub/stylesheets/navigation.css"))
	       :test puri:uri=))

(addtest widget-dependencies-2
  (ensure-same
   (mapcar #'dependency-url
	   (dependencies (make-instance 'gridedit :data-class 'employee)))
   ;; note, pagination and dataform are there because for gridedit and
   ;; datagrid widget-dependencies is specialized
   '(#U"/pub/stylesheets/dataform.css" #U"/pub/stylesheets/pagination.css"
     #U"/pub/stylesheets/datagrid.css" #U"/pub/scripts/datagrid.js"
     #U"/pub/stylesheets/dataseq.css")
   :test set-equal-uri=))

(deftest widget-dependencies-3
    (with-request :get nil
      (dependencies 'test))
  nil)

;;; test render-widget-body
(deftest-html render-widget-body-1
    (render-widget-body (lambda (&rest args)
			  (with-html (:p "blah"))))
  (:p "blah"))

(deftest-html render-widget-body-2
    (render-widget-body "test")
  (:p "test"))

(deftest-html render-widget-body-3
    (render-widget-body "test" :id "foo" :class "bar")
  (:p :id "foo" :class "bar" "test"))

;; helper function
(defun dummy-symbol-function (&rest args)
  (with-html (:p "test")))

(deftest-html render-widget-body-4
    (render-widget-body 'dummy-symbol-function)
  (:p "test"))

;;; test dom-classes
(deftest dom-classes-1
    (dom-classes #'identity)
  "widget function")

(deftest dom-classes-2
    (dom-classes 'identity)
  "widget function identity")

(deftest dom-classes-3
    (dom-classes "test")
  "widget string")

(deftest dom-classes-4
    (with-request :get nil
      (dom-classes (make-instance 'gridedit
					 :data-class 'employee)))
  "widget dataseq datagrid dataedit-mixin gridedit")

;;; test with-widget-header
(deftest-html with-widget-header-1
    (with-request :get nil
      (with-widget-header (make-instance 'dataform :data *joe*)
	(lambda (obj &rest args)
	  (with-html (:p "test")))
	:widget-prefix-fn (lambda (&rest args) (with-html (:p "hello")))
	:widget-suffix-fn (lambda (&rest args) (with-html (:p "world")))))
  (:div :class "widget data-editor dataform" :id "id-123"
	(:p "hello")
	(:p "test")
	(:p "world")))

;;; test widget-name specialization for widgets
(deftest widget-name-1
    (widget-name #'identity)
  nil)

(deftest widget-name-2
    (widget-name "identity")
  nil)

(deftest widget-name-3
    (widget-name 'identity)
  identity)

;;; test ensure-widget-methods

(defgeneric ewm-g0 ())
(defgeneric ewm-g1 (a &optional b))
(defgeneric ewm-g2 (a b &rest c))
(defgeneric ewm-g5 (a b c d e))

(defun widget-class-count ()
  (length weblocks::*widget-classes*))

(addtest ensure-widget-methods-0
  (remove-all-methods #'ewm-g0)
  (ensure-widget-methods #'ewm-g0 '() (constantly 42))
  (ensure-same (generic-function-methods #'ewm-g0) '()))

(addtest ensure-widget-methods-1
  (remove-all-methods #'ewm-g1)
  (ensure-widget-methods #'ewm-g1 0 (lambda (n &optional m)
				      (declare (ignore n m))
				      42))
  (ensure-same (ewm-g1 (make-instance 'composite)) 42)
  (ensure-same (length (generic-function-methods #'ewm-g1))
	       (widget-class-count)))

(addtest ensure-widget-methods-2
  (remove-all-methods #'ewm-g2)
  (ensure-widget-methods #'ewm-g2 1 (lambda (a b &rest c)
				      (declare (ignore a b c))
				      84))
  (ensure-same (ewm-g2 t (make-instance 'composite)) 84)
  (ensure-same (length (generic-function-methods #'ewm-g2))
	       (widget-class-count)))

(addtest ensure-widget-methods-5
  (remove-all-methods #'ewm-g5)
  (ensure-widget-methods #'ewm-g5 '(3 1)
			 (lambda (a b c d e)
			   (list b a c d e)))
  (ensure-same (ewm-g5 1 'two 3 'four 5)
	       '(two 1 3 four 5))
  (ensure-same (length (generic-function-methods #'ewm-g5))
	       (expt (widget-class-count) 2)))

;;; widget-designator typechecking
(addtest nil-is-not-valid
  (ensure-same (typep nil 'weblocks::widget-designator)
	       (values nil t))
  (ensure-null (weblocks::widget-designator-p nil)))

(addtest widget-designator-export-status-same
  (ensure-same (symbol-status 'weblocks::widget-designator)
	       (symbol-status 'weblocks::widget-designator-p)))

(addtest widget-designator-type-not-extensible
  (ensure-null
   (typep #'weblocks::widget-designator-p 'generic-function)))

;;; test composite-widgets specialization for widgets
(deftest composite-widgets-1
    (composite-widgets #'identity)
  nil)

(deftest composite-widgets-2
    (composite-widgets "identity")
  nil)

(deftest composite-widgets-3
    (composite-widgets 'identity)
  nil)

(deftest composite-widgets-4
    (with-request :get nil
      (let ((w (make-instance 'composite)))
	(setf (composite-widgets w) 1)
	(composite-widgets w)))
  (1))

(deftest composite-widgets-5
    (with-request :get nil
      (let ((w (make-instance 'composite)))
	(setf (composite-widgets w) nil)
	(composite-widgets w)))
  nil)

(deftest composite-widgets-6
    (with-request :get nil
      (let ((w (make-instance 'composite)))
	(setf (composite-widgets w) (list 1))
	(composite-widgets w)))
  (1))

;;; render function as a widget
(deftest-html render-function-1
    (with-request :get nil
      (render-widget (lambda (&rest args)
		       (with-html (:p "blah")))))
  (:div :class "widget function"
	(:p "blah")))

;;; render some other widget without a name
(deftest-html render-widget-1
    (with-request :get nil
      (render-widget (make-instance 'dataform :data *joe*)))
  (:div :class "widget data-editor dataform" :id "id-123"
	#.(data-header-template
	   "abc123"
	   '((:li :class "name" (:span :class "label text" "Name:&nbsp;") (:span :class "value" "Joe"))
	     (:li :class "manager" (:span :class "label text" "Manager:&nbsp;")
	      (:span :class "value" "Jim"))))))

;;; render some widget with a name
(deftest-html render-widget-2
    (with-request :get nil
      (render-widget (make-instance 'dataform :data *joe* :name "Test Widget")))
  (:div :class "widget data-editor dataform" :id "test-widget"
	#.(data-header-template
	   "abc123"
	   '((:li :class "name" (:span :class "label text" "Name:&nbsp;") (:span :class "value" "Joe"))
	     (:li :class "manager" (:span :class "label text" "Manager:&nbsp;")
	      (:span :class "value" "Jim"))))))

(deftest-html render-widget-3
    (with-request :get nil
      (render-widget (make-instance 'dataform :data *joe*) :inlinep t))
  #.(data-header-template "abc123"
     '((:li :class "name" (:span :class "label text" "Name:&nbsp;") (:span :class "value" "Joe"))
       (:li :class "manager" (:span :class "label text" "Manager:&nbsp;") (:span :class "value" "Jim")))))

(deftest render-widget-4
    (let ((*weblocks-output-stream* (make-string-output-stream)))
      (declare (special *weblocks-output-stream*))
      (with-request :get nil
	(render-widget (make-instance 'dataform :data *joe*))
	(format nil "~A" (mapcar #'dependency-url weblocks::*page-dependencies*))))
  "(/pub/stylesheets/dataform.css)")

(deftest render-widget-5
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((w (make-instance 'dataform :data *joe*))
	      res1 res2)
	  (setf res1 (widget-rendered-p w))
	  (render-widget w :inlinep t)
	  (setf res2 (widget-rendered-p w))
	  (values res1 res2))))
  nil t)

;;; test mark-dirty
(deftest mark-dirty-1
    (multiple-value-bind (res errors)
	(ignore-errors (mark-dirty (lambda () nil)))
      (values res (null errors)))
  nil nil)

(deftest mark-dirty-2
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'composite :name "test")))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (mark-dirty w)
	  (widget-name (car weblocks::*dirty-widgets*)))))
  "test")

(deftest mark-dirty-3
    (with-request :get nil
      (let ((weblocks::*dirty-widgets* nil)
	    (w (make-instance 'composite :name "test")))
	(declare (special weblocks::*dirty-widgets*))
	(mark-dirty w)
	(widget-name (car weblocks::*dirty-widgets*))))
  nil)

(deftest mark-dirty-4
    (with-request :get nil
      (setf (session-value 'weblocks::root-composite) (create-site-layout))	
      (let ((weblocks::*dirty-widgets* nil))
	(declare (special weblocks::*dirty-widgets*))
	(mark-dirty (make-instance 'composite :name "test"
				   :propagate-dirty '((root-inner test-nav-1 test2 test2-leaf)))
		    :putp t)
	(mapcar #'widget-name weblocks::*dirty-widgets*)))
  nil)

#+(or)
(deftest mark-dirty-5
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(setf (root-composite) (create-site-layout))	
	(let* ((weblocks::*dirty-widgets* nil)
	       (path '((root-inner test-nav-1 test2 test2-leaf)))
	       (w (make-instance 'composite :name "test"
					    :propagate-dirty path)))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (render-widget (find-widget-by-path (car path)))
	  (mark-dirty w :putp t)
	  (mapcar #'widget-name weblocks::*dirty-widgets*))))
  (test2-leaf "test"))

(deftest mark-dirty-6
    (with-request :get nil
      (let ((weblocks::*dirty-widgets* nil)
	    (w (make-instance 'composite :name "test")))
	(declare (special weblocks::*dirty-widgets*))
	(setf (widget-rendered-p w) t)
	(widget-name (car weblocks::*dirty-widgets*))))
  nil)

;;; test widget-dirty-p
(deftest widget-dirty-p-1
    (let ((weblocks::*dirty-widgets* nil)
	  (w (make-instance 'composite :name "test")))
      (declare (special weblocks::*dirty-widgets*))
      (widget-dirty-p w))
  nil)

(deftest widget-dirty-p-2
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'composite :name "test")))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (mark-dirty w)
	  (not (null (widget-dirty-p w))))))
  t)

;;; test that (setf slot-value-using-class) method is modified for
;;; widgets to automatically mark them as dirty
(deftest setf-slot-value-using-class-1
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'dataform)))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (setf (dataform-ui-state w) :form)
	  (widget-name (car weblocks::*dirty-widgets*)))))
  "id-123")

(deftest setf-slot-value-using-class-2
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'dataform)))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  weblocks::*dirty-widgets*)))
  nil)

;;; test find-widget-by-path
(deftest find-widget-by-path-1
    (find-widget-by-path '(hello) nil)
  nil)

(deftest find-widget-by-path-2
    (find-widget-by-path nil 'hello)
  hello)

(deftest find-widget-by-path-3
    (with-request :get nil
      (setf (root-composite) (create-site-layout))
      (let ((res (find-widget-by-path '(root-inner test-nav-1 test2 test2-leaf))))
	(values (widget-name res)
		(type-of res))))
  test2-leaf composite)

(deftest find-widget-by-path-4
    (with-request :get nil
      (setf (session-value 'weblocks::root-composite) (create-site-layout))
      (find-widget-by-path '(doesnt exist)))
  nil)

(deftest find-widget-by-path-5
    (with-request :get nil :uri "/test2"
      (setf (root-composite) (create-site-layout))
      (catch 'hunchentoot::handler-done
	(handle-client-request (weblocks::current-webapp)))
      (let ((test2 (find-widget-by-path '(root-inner test-nav-1 test2))))
	(values (widget-name test2)
		(type-of test2))))
  "test2" composite)

;;; test customized widget printing
(deftest widget-printing-1
    (progv '(*package*) (list (find-package :weblocks-test))
      (format nil "~s" (make-instance 'weblocks::navigation :dom-id nil)))
  "#<NAVIGATION NIL>")

(deftest widget-printing-2
    (progv '(*package*) (list (find-package :weblocks-test))
      (format nil "~s" (make-instance 'weblocks::dataform :name 'users)))
  "#<DATAFORM USERS>")

;; navigation is no longer a special case which DOES NOT autogenerate ids
(deftest widget-printing-3
    (with-request :get nil
      (progv '(*package*) (list (find-package :weblocks-test))
	(format nil "~s" (make-instance 'weblocks::navigation))))
  "#<NAVIGATION \"id-123\">")

(deftest widget-printing-4
    (with-request :get nil
      (progv '(*package*) (list (find-package :weblocks-test))
	(format nil "~s" (make-instance 'weblocks::navigation :dom-id "id-234"))))
  "#<NAVIGATION \"id-234\">")