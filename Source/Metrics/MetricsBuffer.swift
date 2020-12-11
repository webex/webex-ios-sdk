// Copyright 2016-2021 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import ObjectMapper

class MetricsBuffer: NSObject {
    private var metrics = [[String: Any]]()
    private var clientMetrics = [[String: Any]]()
    
    func add(metric: Metric) {
        synchronized(lock: self) {
            self.metrics.append(makePayloadWith(metric: metric))
        }
    }
    
    func add(clientMetric: ClientMetric) {
        synchronized(lock: self) {
            self.clientMetrics.append(Mapper().toJSON(clientMetric))
        }
    }
    
    func popAll(client: Bool) -> [[String: Any]]? {
        var ret: [[String: Any]]?
        synchronized(lock: self) {
            if client && self.clientMetrics.count > 0 {
                ret = self.clientMetrics
                self.clientMetrics.removeAll()
            }
            else if !client && self.metrics.count > 0 {
                ret = self.metrics
                self.metrics.removeAll()
            }
        }
        return ret
    }
    
    func count(client: Bool) -> Int {
        var ret = 0
        synchronized(lock: self) {
            if client {
                ret = self.clientMetrics.count
            }
            else {
                ret = self.metrics.count
            }
        }
        return ret
    }
    
    private func makePayloadWith(metric: Metric) -> [String: Any] {
        var payload: [String: Any] = metric.data
        payload["key"] = metric.name
        payload["time"] = metric.time
        payload["postTime"] = Timestamp.nowInUTC
        payload["type"] = metric.type.rawValue
        if metric.background {
            payload["background"] = String(metric.background)
        }
        return payload
    }
}
