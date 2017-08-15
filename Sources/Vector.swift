import GSLApi
import Foundation

open class GSLVector: Equatable, CustomStringConvertible {
  let reference: UnsafeMutablePointer<gsl_vector>

  public static func == (l: GSLVector, r: GSLVector) -> Bool {
    return 1 == gsl_vector_equal(l.reference, r.reference)
  }

  public static func Swap(v: GSLVector, w: GSLVector) {
    _ = gsl_vector_swap(v.reference, w.reference)
  }

  public init(size: Int) {
    reference = gsl_vector_calloc(size)
  }

  public init(size: Int, data: String? = nil) {
    reference = gsl_vector_calloc(size)
    guard let dat = data else { return }
    var fnumbers:[Int32] = [0, 0]
    guard 0 == pipe(&fnumbers),
      let fr = fdopen(fnumbers[0], "r"),
      let fw = fdopen(fnumbers[1], "w")
      else {
        return
    }
    defer {
      fclose(fr)
    }
    let written = dat.withCString { ptr -> Int in
      return fwrite(ptr, 1, dat.characters.count, fw)
    }
    fclose(fw)
    guard written > 0 else { return }
    _ = gsl_vector_fscanf(fr, reference)
  }

  public var isNull: Bool {
    return gsl_vector_isnull(reference) > 0
  }

  public var isPos: Bool {
    return gsl_vector_ispos(reference) > 0
  }

  public var isNeg: Bool {
    return gsl_vector_isneg(reference) > 0
  }

  public var isNonneg: Bool {
    return gsl_vector_isnonneg(reference) > 0
  }

  public var size: Int {
    return reference.pointee.size
  }

  public var copy: GSLVector {
    let u = GSLVector(size: self.size)
    _ = gsl_vector_memcpy(u.reference, self.reference)
    return u
  }

  public var value: [Double] {
    var v: [Double] = []
    for i in 0 ..< self.size {
      v.append(self.get(i))
    }
    return v
  }

  public var description: String {
    var fnumbers:[Int32] = [0, 0]
    guard 0 == pipe(&fnumbers),
      let fr = fdopen(fnumbers[0], "r"),
      let fw = fdopen(fnumbers[1], "w")
      else {
        return "{\"error\": \"streaming failed\"}"
    }
    gsl_vector_fprintf(fw, reference, "%g")
    fclose(fw)
    var dataString = ""
    let szbuf = 4096
    var buf = UnsafeMutablePointer<CChar>.allocate(capacity: szbuf)
    defer {
      fclose(fr)
      buf.deallocate(capacity: szbuf)
    }
    while 0 == feof(fr) {
      memset(buf, 0, szbuf)
      let sz = fread(buf, 1, szbuf - 1, fr)
      if sz < 1 { break }
      dataString.append(String(cString: buf))
    }
    return dataString
  }

  public func `export`(stream: UnsafeMutablePointer<FILE>) throws {
    guard 0 == gsl_vector_fwrite(stream, reference) else {
      throw GSLErrors.InvalidFilePointer
    }
  }

  public func `import`(stream: UnsafeMutablePointer<FILE>) throws {
    guard 0 == gsl_vector_fread(stream, reference) else {
      throw GSLErrors.InvalidFilePointer
    }
  }

  public func `export`(path: String) throws {
    guard let f = fopen(path, "wb") else {
      throw GSLErrors.InvalidFilePointer
    }
    defer {
      fclose(f)
    }
    try self.export(stream: f)
  }

  public func `import`(path: String) throws {
    guard let f = fopen(path, "rb") else {
      throw GSLErrors.InvalidFilePointer
    }
    defer {
      fclose(f)
    }
    try self.import(stream: f)
  }

  public func `get`(_ index: Int) -> Double {
    return gsl_vector_get(reference, index)
  }

  public func `set`(_ index: Int, value: Double) {
    gsl_vector_set(reference, index, value)
  }

  deinit {
    gsl_vector_free(reference)
  }
}
