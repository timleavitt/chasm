(require hyrule [unless])

(import json)
(import zmq)

(import chasm-client.lib [config])
(import chasm-client.wire [wrap unwrap])


(setv REQUEST_TIMEOUT 120 ; seconds
      context (zmq.Context))
(setv player (config "name"))


(defn start-socket []
  (setv socket (.socket context zmq.REQ))
  ; see https://stackoverflow.com/questions/26915347/zeromq-reset-req-rep-socket-state
  (.setsockopt socket zmq.RCVTIMEO (* REQUEST_TIMEOUT 1000))
  (.setsockopt socket zmq.REQ_CORRELATE 1)
  (.setsockopt socket zmq.REQ_RELAXED 1)
  (.connect socket (config "server"))
  socket)

(setv socket (start-socket))


(defn rpc [payload]
  "Call a function on the server. Return None for timeout."
  (try
    (.send-string socket (wrap payload))
    (:payload (unwrap (.recv-string socket)))
    (except [zmq.Again]
      {"role" "error" "content" "Request timed out."})))

(defn send-quit [#* args #** kwargs]
  "This is a parse request but with no waiting."
  (.send-string socket (wrap {"function" "parse"
                              "args" args
                              "kwargs" kwargs})))

(defn spawn [#* args #** kwargs]
  (rpc {"function" "spawn"
        "args" args
        "kwargs" kwargs}))

(defn parse [#* args #** kwargs]
  (rpc {"function" "parse"
        "args" args
        "kwargs" kwargs}))
