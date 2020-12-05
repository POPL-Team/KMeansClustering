#lang racket
(require 2htdp/batch-io)
(require csv-writing)

 #|This function recersively calls itself in order to convert the
   data from strings into floats using convertElement defined below.
   This will return a list converted from string to floats|#
(define (convertList List)
  (if (equal? (length List) 1)
      (list (convertElement (car List)))
      (cons (convertElement (car List)) (convertList (cdr List)))
  )
)

#|ConvertElements will take an element(a list) and convert
  said element into a float.
  This will then return a list of two elements containing floats|#
(define (convertElement element)
  (list (string->number (car element)) (string->number (car (cdr element)))))

#|This is our original list that we use.
  It is retrieved from a .csv file and saved as List|#
(define List
  (convertList (cdr (read-csv-file "lengthVsHeight.csv")))
)

#|These are the range and domain of data stored for later use|#
(define minNum 20)
(define maxNum 40)

#|This is our K value aka our number of centroids|#
(define K 4)

(define (getRandomElement List)
  (define element (list-ref List (random 0 (length List))))
  (list element (remove element List))
)

#| Simple average of a list. This isn't related to centroids like the one below so it's much simpler. |#
(define (average List)
  (define avg (list 0 0))
  (for ([i (in-range 0 (length List))])
    (set! avg (list (+ (car avg) (car (list-ref List i))) (+ (car (cdr avg)) (car (cdr (list-ref List i))))))
  )

  (set! avg (list (/ (car avg) (length List)) (/ (car (cdr avg)) (length List))))
  avg
)

#| Remove partitionSize elements from List. Return as a pair (extracted, restofList) |#
(define (extract partitionSize List)
  (define tempList List)
  (define extractedList (getRandomElement tempList))
  (define output (list (car extractedList)))

  (for ([i (in-range 0 (- partitionSize 1))])
    #| If there aren't enough elements, just use the rest of the list |#
    (if (not (equal? (length (car (cdr extractedList))) 0))
        (begin
          (set! extractedList (getRandomElement (car (cdr extractedList))))
          (set! output (append output (list (car extractedList))))
        )
        void
    )
  )
  (list output (car (cdr extractedList)))
)

#| These will be defined later|#
(define centroids (list
  (list 0 0)
  (list 0 0)
  (list 0 0)
  (list 0 0)
  )
)

#| Partition List into K disjoint subLists |#
(define (kbags K List)
  (define partitionSize (ceiling (/ (length List) K)))
  #| splitList will contain the i-th split, and the rest of the list |#
  (define splitList (list 0 List))
  (for ([i (in-range 0 K)])
    (set! splitList (extract partitionSize (car (cdr splitList))))
    #| First element is (car splitList) |#
    #| Second element is (car (cdr splitList)) |#
    #| Update centroids with the average of i-th of the subLists |#
    (set! centroids (list-set centroids i (average (car splitList))))
    #| Remove the brackets around the second element of splitList because racket sucks |#
    (set! splitList (list-set splitList 1 (car (cdr splitList))))
  )
)

(kbags K List)

#|This function will find the get the square root of
  the result of distance helper.
  This returns the distance between to points witin a 2D space|#
(define (distance list1 list2)
  (sqrt (distanceHelper list1 list2)))

#|DistanceHelper will take two points as lists and recusively calculate
  the summation of (delta n)^2 up to the end of the list
  This returns the result of the calculation |#
(define (distanceHelper list1 list2)
  (if (equal? (length list1) 1)
      (expt (- (car list1) (car list2)) 2)
      (+ (expt (- (car list1) (car list2)) 2) (distanceHelper (cdr list1) (cdr list2)))
  )
)

#|This funcion will recusively creat a list of the closest points to the centroid
  It will return the list of assiciated points|#
(define (associate centroidList List)
  (if (equal? (length List) 1)
      (list (getAssociation centroidList (car List) +inf.f (list -100 -100)))
      (cons (getAssociation centroidList (car List) +inf.f (list -100 -100)) (associate centroidList (cdr List)))
  )
)

#|getAssociation will use distance to determine the clostes points to the centroids
  coordinates. It will recusively iterate through centroidList.
  This returns the list of closest data points|#
(define (getAssociation centroidList element minDistance currentCentroid)
  (if (equal? (length centroidList) 0)
      (list currentCentroid element)
      (if (> minDistance (distance element (car centroidList)))
          (getAssociation (cdr centroidList) element (distance element (car centroidList)) (car centroidList))
          (getAssociation (cdr centroidList) element minDistance currentCentroid)
      )
  )
)

#|ComputeAverage will take the centroids and the original List
  It will go though each centroid in centoidList and use the distance found
  to set the centoids to the new coordinated as the averages.
  It will return the updated centroidList|#
(define (computeAverage centroidList List)
  (define temp (list 0 0 0 0))
  (define avg (list 0 0))
  (define count (length List))
  (define currentCentroid (list 0 0))
  (define currentElement (list 0 0))
  
  (for ([i (in-range 0 (length centroidList))])
    (set! currentCentroid (list-ref centroidList i))
    (set! avg (list 0 0))
    (set! count (length List))
    (for ([j (in-range 0 (length List))])
      (set! currentElement (car (cdr (list-ref List j))))
      (if (equal? currentCentroid (car (list-ref List j)))
          (set! avg (list (+ (car avg) (car currentElement)) (+ (car (cdr avg)) (car (cdr currentElement)))))
          (set! count (- count 1))
      )
    )
    (if (equal? count 0)
        (set! count 1)
        void
    )
    (set! avg (list (/ (car avg) count) (/ (car (cdr avg)) count)))

    (if (not (and (equal? (list-ref avg 0) 0) (equal? (list-ref avg 1) 0)))
        (set! centroidList (list-set centroidList i avg))
        void
    )
  )
  centroidList
)

(define out (open-output-file "centroids.csv" #:mode 'text #:exists 'truncate))
(display-table (list (list "x" "y")) out)
#|Kmeanscluster will recusively iterate through the K-means algorithm
  and keep looping until both coodinates of the prievious and current
  iteration are identical
  This will return nothing|#
(define (kmeanscluster centroids previous-centroids)
  (if (equal? previous-centroids 0)
      void
      (display-table previous-centroids out)
  )
      
  (define centroidList (computeAverage centroids (associate centroids List)))
  (if (equal? previous-centroids centroids)
      (write "Complete")
      (kmeanscluster centroidList centroids)
   )
)

(kmeanscluster centroids 0)
(close-output-port out)