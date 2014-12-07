(load "package://jsk_calibration/euslisp/calibration.l")

(defmethod euscollada-robot
  (:reset-pose-for-leg-calibration ()   ;only for hrp2 robots
    (send self :reset-manip-pose)
    (send self :larm :elbow-p :joint-angle 0)
    (send self :rarm :elbow-p :joint-angle 0)
    (send self :angle-vector)))

(defclass hrp2-calibration-config
  :super calibration-config
  :slots (reset-angles))

(defmethod hrp2-calibration-config
  (:init (&key ((:model-file amodel-file) nil)
               ((:model-class amodel-class) nil)
               (camera-method nil))
    (send-super :init :model-file amodel-file :model-class amodel-class)
    (send self :head-camera-config "/camera_remote/rgb")
    (send self :add-board-object (make-mmurooka-board))
    (send self :add-chain-configs
          (list (cons "LARM" (butlast (send robot :larm)))
                (cons "RARM" (butlast (send robot :rarm)))
                (cons "LLEG" (send robot :lleg))
                (cons "RLEG" (send robot :rleg))
                (cons "head" (send robot :head))
                (cons "torso"
                      (send robot :torso))))
    ;; build good collision links
    (let ((collision-links (send robot :collision-check-pairs))
          (ignore-link-pairs nil))
          ;; (ignore-link-pairs '(("LARM_LINK6" . "LARM_LINK4")
          ;;                      ("RARM_LINK6" . "RARM_LINK4"))))
      (setq collision-links
            (remove-if #'(lambda (pair)
                           (let ((a (send (car pair) :name))
                                 (b (send (cdr pair) :name)))
                             (or (member (cons a b) ignore-link-pairs
                                         :test #'equal)
                                 (member (cons b a) ignore-link-pairs
                                         :test #'equal))))
                       collision-links))
      (send self :add-motion :larm
            (instance calibration-motion
                      :init
                      :prompt "Please put the checkerboard in the left hand"
                      :chain-ids '("LARM_chain" "head_chain")
                      :limb :larm
                      :collision-links collision-links
                      :robot-model robot
                      :reset-method :reset-pose
                      :camera-method camera-method
                      :filter-sampling-coords
                      '(lambda (c)
                         (> (elt (send c :worldpos) 1) 0))
                      :sampling-joint
                      (list
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-p)
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-y)
                                 :min-angle 0
                                 :step-angle 15))
                      :distances
                      (range-equivalents 520 640 60)
                      :angles 
                      (range-equivalents (deg2rad -30) (deg2rad 120) (deg2rad 30))
                      :x-angles
                      (list (deg2rad -10) (deg2rad 0) (deg2rad 10))
                      :y-angles
                      (list (deg2rad -10) (deg2rad 0) (deg2rad 10))
                      :board (make-mmurooka-board)
                      :end-effector-offset
                      (let ((c (make-coords :pos (float-vector (+ 100) (+ 70 65 80) 0))))
                        (send c :rotate (deg2rad -90) :y)
                        (send c :rotate (deg2rad 90) :z)
                        c)))
      (send self :add-motion :rarm
            (instance calibration-motion
                      :init
                      :prompt "Please put the checkerboard in the right hand"
                      :chain-ids '("RARM_chain" "head_chain")
                      :limb :rarm
                      :angles           ;-90
                      ;;(list (deg2rad -30))
                      (range-equivalents (deg2rad -100) (deg2rad 0) (deg2rad 30))
                      :x-angles
                      (list (deg2rad -10) (deg2rad 0) (deg2rad 10))
                      :y-angles
                      (list (deg2rad -10) (deg2rad 0) (deg2rad 10))
                      :collision-links collision-links
                      :robot-model robot
                      :reset-method :reset-pose
                      :camera-method camera-method
                      :filter-sampling-coords
                      '(lambda (c)
                         (< (elt (send c :worldpos) 1) 0))
                      :sampling-joint
                      (list
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-p)
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-y)
                                 :step-angle 15))
                      :distances
                      (range-equivalents 520 720 60)
                      :board (make-mmurooka-board)
                      :end-effector-offset
                      (let ((c (make-coords
                                :pos (float-vector (+ 100) (- (+ 70 65 80)) 0))))
                        (send c :rotate (deg2rad -90) :y)
                        (send c :rotate (deg2rad 90) :z)
                        c)))
      (send self :add-motion :lleg
            (instance calibration-motion
                      :init
                      :prompt "Please put the checkerboard in the left leg"
                      :chain-ids '("LLEG_chain" "torso_chain" "head_chain")
                      :limb :lleg
                      :collision-links collision-links
                      :robot-model robot
                      :reset-method :reset-pose-for-leg-calibration
                      :camera-method camera-method
                      :angles ;;(list (deg2rad 90))
                      (range-equivalents (deg2rad 30) (deg2rad 150) (deg2rad 30))
                      :x-angles
                      (list 0 (deg2rad -10) (deg2rad 10))
                      :y-angles
                      (list 0 (deg2rad -10) (deg2rad 10))
                      :filter-sampling
                      '(lambda (neck-p neck-y waist-y waist-p)
                         (>= (+ neck-y waist-y) 0))
                      :sampling-joint
                      (list
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-p)
                                 :min-angle 20
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-y)
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :torso :waist-y)
                                 :min-angle -35
                                 :max-angle 35
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :torso :waist-p)
                                 :max-angle 30
                                 :min-angle 0
                                 :step-angle 15))
                      :distances
                      (range-equivalents 1000 1300 100)
                      :board (make-mmurooka-board)
                      :end-effector-offset
                      (let ((c (make-coords :pos (float-vector (+ 120 70 65) 0 0))))
                        c)))
      (send self :add-motion :rleg
            (instance calibration-motion
                      :init
                      :prompt "Please put the checkerboard in the right leg"
                      :chain-ids '("RLEG_chain" "torso_chain" "head_chain")
                      :limb :rleg
                      :angles
                      (range-equivalents (deg2rad 30) (deg2rad 150) (deg2rad 30))
                      :x-angles
                      (list (deg2rad 0) (deg2rad -10) (deg2rad 10))
                      :y-angles
                      (list (deg2rad 0) (deg2rad 10) (deg2rad 10))
                      :collision-links collision-links
                      :robot-model robot
                      :reset-method :reset-pose-for-leg-calibration
                      :camera-method camera-method
                      :filter-sampling
                      '(lambda (neck-p neck-y waist-y waist-p)
                         (<= (+ neck-y waist-y) 0))
                      :sampling-joint
                      (list
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-p)
                                 :min-angle 20
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :head :neck-y)
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :torso :waist-y)
                                 :min-angle -35
                                 :max-angle 35
                                 :step-angle 15)
                       (instance sample-joint-information :init
                                 :joint (send robot :torso :waist-p)
                                 :max-angle 30
                                 :min-angle 0
                                 :step-angle 15))
                      :distances
                      (range-equivalents 1000 1300 100)
                      :board (make-mmurooka-board)
                      :end-effector-offset
                      (let ((c (make-coords :pos (float-vector (+ 120 70 65) 0 0))))
                        c)))
      self))
  )
(defun test ()
  (setq *calib* (instance hrp2-calibration-config
                          :init
                          :model-file "package://hrpsys_ros_bridge_tutorials/euslisp/hrp2jsknt-interface.l"
                          :model-class 'hrp2jsknt-robot
                          :camera-method :carmine))
  (send *calib* :generate-motions)
  (send *calib* :generate-files "package://jsk_calibration/hrp2jsknt_calibration")
  )

;; (load "hrp2-calibration.l")
;; (test)
;; (send *calib* :generate-files "package://jsk_calibration/hrp2jsknt_calibration")
;; (send *calib* :generate-motions)
;; (send *calib* :refine-motions)
;; (send *calib* :animate)
;; (send-all (mapcar #'(lambda (m) (cdr m)) (send *calib* :motions)) :animate)
;; (send (cdr (car (send *calib* :motions))) :generate-motion)
;; (setq *hrp2* (send (cdr (car (send *calib* :motions))) :robot-model))
;; (send (cdr (car (send *calib* :motions))) :refine-motion)
;; (send (cdr (car (send *calib* :motions))) :animate)
;; (send (cdr (cadr (send *calib* :motions))) :generate-motion)
;; (send (cdr (car (send *calib* :motions))) :test-with-real-robot *ri*)