interface String {
  format(...value: any[]): string;
}

if (!String.prototype.format) {
  String.prototype.format = function (...args: any[]) {
    return this.replace(/{(\d+)}/g, function (match, number) {
      return typeof args[number] != "undefined" ? args[number] : match;
    });
  };
}
